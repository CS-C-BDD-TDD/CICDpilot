require 'securerandom'

module SecureRandom

  def self.stix_id(obj)
    new_id = (obj.respond_to?(:guid) && obj.guid.nil?) ? self.uuid : obj.guid
    "#{Setting.STIX_PREFIX}:#{self.stixish(obj.class.to_s)}-#{new_id}"
  end

  def self.cybox_object_id(obj)
    self.stix_id(obj)
  end

  # Translate to a more canonical STIX/CYBOX name (or return unchanged).

  def self.stixish(str)
    case str
      when 'CyboxCustomObject'  then 'CustomObject'
      when 'CyboxFile'          then 'File'
      when 'CyboxFileHash'      then 'FileHash' # Only needed for Big Migration
      when 'CyboxMutex'         then 'Mutex'
      when 'DnsRecord'          then 'DNSRecord'
      when 'HttpSession'        then 'HTTPSession'
      when 'StixMarking'        then 'DataMarking'
      when 'StixPackage'        then 'Package'
      when 'Registry'           then 'WinRegistry'
      when 'Uri'                then 'URI'
      else str
    end
  end

end
