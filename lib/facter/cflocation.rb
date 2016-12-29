#
# Copyright 2016 (c) Andrey Galkin
#

Facter.add('cf_location') do
    setcode do
        if File.exists? '/etc/cflocation'
            File.read('/etc/cflocation').strip
        else
            'default'
        end
    end 
end
