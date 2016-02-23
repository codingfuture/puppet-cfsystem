Facter.add('cf_location') do
    setcode do
        if File.exists? '/etc/cflocation'
            File.read('/etc/cflocation')
        else
            'default'
        end
    end 
end
