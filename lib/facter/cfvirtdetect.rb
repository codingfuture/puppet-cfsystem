

Facter.add('cf_virt_detect') do
    setcode do
        Facter::Core::Execution.exec('/usr/bin/systemd-detect-virt')
    end 
end
