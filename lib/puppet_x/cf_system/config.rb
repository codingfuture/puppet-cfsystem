#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Done this way due to some weird behavior in tests also ignoring $LOAD_PATH
require File.expand_path( '../../cf_system', __FILE__ )

module PuppetX::CfSystem

class Config
    include Puppet::Util::Logging
    Puppet::Util.logmethods(self, true)
    
    def initialize(file)
        @file = file
        @save_handlers = {}
        @generator_version = PuppetX::CfSystem.makeVersion(__FILE__)
        
        conf = {
            'generator_version' => '',
            'sub_versions' => {},
            'sections' => {},
            'persistent' => {},
        }
        
        @old_config = conf
        @new_config = conf.clone
        
        return conf if not File.exist?(file)

        begin
            confread = JSON.parse(File.read(file))
            
             if confread['generator_version'] != @generator_version
                warning('Config generator version mismatch: ' + confread['generator_version'])
            end
            
            conf.merge! confread
            debug "Read: " + conf.to_s
            @new_config['persistent'] = conf['persistent']
        rescue => e
            warning("Error during old config read: #{e}")
        end
    end
    
    def set_save_handler(type, version, &block)
        conf = @new_config
        conf['sub_versions'][type] = version
        @save_handlers[type] = block
    end
    
    def save
        old_subver = @old_config['sub_versions']
        conf = @new_config
        conf['generator_version'] = @generator_version

        #---
        sections = conf['sections']
        old_sections = @old_config['sections']
        subver = conf['sub_versions']
        
        # sort sections
        sorted_sections = {}
        sections.keys.sort.each do |k|
                sorted_sections[k] = sections[k]
        end
        sections.replace sorted_sections
        
        exceptions = []

        # process each section
        sections.each do |section_name, section_conf|
            sorted_section = {}
            section_conf.keys.sort.each do |k|
                sorted_section[k] = section_conf[k]
            end
            section_conf.replace sorted_section
            
            #---
            if not subver.has_key? section_name
                next
            end
            
            if (old_subver.has_key? section_name and
                old_subver[section_name] == subver[section_name] and
                old_sections.has_key? section_name and
                section_conf == old_sections[section_name])
            then
                next
            end
            
            begin
                @save_handlers[section_name].call(section_conf)
            rescue => e
                # force reconfigure
                sections[section_name] = {}
                exceptions << "#{e}\n#{e.backtrace}"
            end
        end
        
        #---
        content = JSON.pretty_generate(conf)
        PuppetX::CfSystem.atomicWrite(@file, content)
        
        if not exceptions.empty?
            fail(exceptions.join("\n"))
        end
    end

    def get_old(type, default=nil)
        sections = @old_config['sections']
        if type and sections.has_key?(type)
            return sections[type]
        end
            
        return default || {}
    end
    
    def get_new(type, default=nil)
        sections = @new_config['sections']
            
        if not sections.has_key?(type)
            begin
                sections[type] = default || {}
            rescue
                return nil
            end
        end
            
        return sections[type]
    end
    
    def get_persistent(type, default=nil)
        persistent = @new_config['persistent']
            
        if not persistent.has_key?(type)
            persistent[type] = default || {}
        end
            
        return persistent[type]
    end
end

end
