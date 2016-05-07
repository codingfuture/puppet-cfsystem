require 'securerandom'

module Puppet::Parser::Functions
    newfunction(:cf_genpass,  :type => :rvalue) do |args|
        len = args[0]
        SecureRandom.base64(len)
    end
end
