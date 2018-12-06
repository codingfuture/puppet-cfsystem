#
# Copyright 2018 (c) Andrey Galkin
#


begin
    require File.expand_path( '../../../../puppet_x/cf_system', __FILE__ )
rescue LoadError
    require File.expand_path( '../../../../../../cfsystem/lib/puppet_x/cf_system', __FILE__ )
end

Puppet::Type.type(:cfsystem_timer).provide(
    :cfprov,
    :parent => PuppetX::CfSystem::ProviderBase
) do
    desc "Provider for cfsystem_timer"
    
    commands :systemctl => PuppetX::CfSystem::SYSTEMD_CTL
        
    def self.get_config_index
        'cf91timer'
    end

    def self.get_generator_version
        cf_system().makeVersion(__FILE__)
    end
    
    def self.check_exists(params)
        debug("check_exists: #{params}")
        begin
            systemctl(['status', "#{params[:name]}.timer"])
        rescue => e
            warning(e)
            #warning(e.backtrace)
            false
        end
    end

    def self.on_config_change(newconf)
        debug('on_config_change')

        new_timers = []

        newconf.each do |name, conf|
            new_timers << name

            begin
                self.send("create_timer", name, conf)
            rescue => e
                warning(e)
                #warning(e.backtrace)
                err("Transition error in setup")
            end
        end
 
        begin
            cf_system.cleanupSystemD("cftimer-", new_timers)
            cf_system.cleanupSystemD("cftimer-", new_timers, 'timer')
        rescue => e
            warning(e)
            #warning(e.backtrace)
            err("Transition error in setup")
        end
    end

    def self.create_timer(service_name, conf)
        debug('on_config_change')
        
        user = conf[:user]
        root_dir = conf[:root_dir]
        settings_tune = (conf[:settings_tune] or {})
        command = conf[:command]
        period = conf[:period]
        calendar = conf[:calendar]
        
        avail_mem = cf_system.getMemory(service_name)

        # Service File
        #==================================================
        content_ini = {
            'Unit' => {
                'Description' => "Service: #{service_name}",
            },
            'Service' => {
                'Type' => 'oneshot',
                'Restart' => 'no',
                'ExecStart' => command,
                'LimitNOFILE' => '16384',
                'WorkingDirectory' => root_dir,
            },
        }

        timer_ini = {
            'Install' => {
                'WantedBy' => 'timers.target',
            },
        }
        
        settings_tune.each { |k, v|
            if k == 'Timer'
                timer_init[k] = v.clone
            else
                content_ini.setdefault(k, {})
                content_ini[k].merge!
            end
        }

        self.cf_system().createService({
            :service_name => service_name,
            :user => user,
            :content_ini => content_ini,
            :cpu_weight => conf[:cpu_weight],
            :io_weight => conf[:io_weight],
            :mem_limit => avail_mem,
            :mem_lock => true,
        })
        self.cf_system().createTimer({
            :service_name => service_name,
            :content_ini => timer_ini,
            :period => period,
            :calendar => calendar,
        })

        systemctl('start', "#{service_name}.timer")
    end
end

