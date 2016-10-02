Facter.add('cf_location_pool') do
    setcode do
        if File.exists? '/etc/cflocationpool'
            File.read('/etc/cflocationpool').strip
        else
            'default'
        end
    end 
end
