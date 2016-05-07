require 'json'

Facter.add('cf_persistent') do
    setcode do
        begin
            json = File.read('/etc/cfsystem.json')
            json = JSON.parse(json)
            json['persistent']
        rescue
            {}
        end
    end 
end
