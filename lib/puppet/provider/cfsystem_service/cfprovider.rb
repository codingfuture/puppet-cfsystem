#
# Copyright 2018 (c) Andrey Galkin
#


begin
    require File.expand_path( '../../../../puppet_x/cf_system', __FILE__ )
rescue LoadError
    require File.expand_path( '../../../../../../cfsystem/lib/puppet_x/cf_system', __FILE__ )
end

Puppet::Type.type(:cfsystem_service).provide(
    :cfprov,
    :parent => PuppetX::CfSystem::ProviderBase
) do
    desc "Provider for cfsystem_service"
    
    commands :systemctl => PuppetX::CfSystem::SYSTEMD_CTL
        
    def self.get_config_index
        'cf91service'
    end

    def self.get_generator_version
        cf_system().makeVersion(__FILE__)
    end
    
    def self.check_exists(params)
        debug("check_exists: #{params}")
        begin
            systemctl(['status', "#{params[:name]}.service"])
        rescue => e
            warning(e)
            #warning(e.backtrace)
            false
        end
    end

    def self.on_config_change(newconf)
        debug('on_config_change')

        new_services = []

        newconf.each do |name, conf|
            new_services << name

            begin
                self.send("create_svc", name, conf)
            rescue => e
                warning(e)
                #warning(e.backtrace)
                err("Transition error in setup")
            end
        end
 
        begin
            cf_system.cleanupSystemD("cfsvc-", new_services)
        rescue => e
            warning(e)
            #warning(e.backtrace)
            err("Transition error in setup")
        end
    end

    def self.create_svc(service_name, conf)
        debug('on_config_change')
        
        user = conf[:user]
        root_dir = conf[:root_dir]
        settings_tune = (conf[:settings_tune] or {})
        command = conf[:command]
        allow_restart = conf[:allow_restart]
        
        avail_mem = cf_system.getMemory(service_name)

        # Service File
        #==================================================
        content_ini = {
            'Unit' => {
                'Description' => "Service: #{service_name}",
            },
            'Service' => {
                'ExecStart' => command,
                'LimitNOFILE' => '16384',
                'WorkingDirectory' => root_dir,
            },
        }
        
        settings_tune.each { |k, v|
            content_ini.setdefault(k, {})
            content_ini[k].merge! v
        }

        service_changed = self.cf_system().createService({
            :service_name => service_name,
            :user => user,
            :content_ini => content_ini,
            :cpu_weight => conf[:cpu_weight],
            :io_weight => conf[:io_weight],
            :mem_limit => avail_mem,
            :mem_lock => true,
        })

        #==================================================
        
        if service_changed and allow_restart
            warning(">> reloading #{service_name}")
            systemctl('restart', "#{service_name}.service")
        else
            systemctl('start', "#{service_name}.service")
        end        
    end
end

