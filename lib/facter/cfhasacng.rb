#
# Copyright 2016-2018 (c) Andrey Galkin
#



Facter.add('cf_has_acng') do
    setcode do
        'yes' if File.exists? '/etc/apt-cacher-ng/acng.conf'
    end 
end
