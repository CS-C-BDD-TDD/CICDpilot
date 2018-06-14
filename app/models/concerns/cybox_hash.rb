class CyboxHash
  def self.generate(str)
    return "" if str.blank?
    d = Digest::SHA2.new << str
    return "#{d.to_s}"
  end
end
