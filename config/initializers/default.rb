require 'socket'
class Default
  class << self
    def SYSTEM_NAME
      return @system_name if @system_name 
      hostname = Socket.gethostname
      name = [hostname]
      Socket.ip_address_list.each do |address|
        if address.ipv4? && 
           !address.ipv4_loopback? &&
           !address.ipv4_multicast?
          name << address.ip_address
        end
      end.compact
      @system_name = name.join("-")
    end

    def method_missing(*args,&block)
      return nil
    end

  end

end
