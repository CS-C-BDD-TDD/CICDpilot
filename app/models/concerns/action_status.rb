# The ActionStatus class functions almost as an enum, representing possible
# statuses for an action, such as an upload. It provides constants like
# ActionStatus::SUCCEEDED, plus iteration: ActionStatus.each {|k, v| ...}

class ActionStatus

  def self.add_item(key, value)
    @hash ||= {}
    @hash[key] = value
  end

  def self.const_missing(key)
    @hash[key]
  end

  def self.each
    @hash.each {|key, value| yield(key, value)}
  end

  self.add_item :NOT_STARTED, 'N'
  self.add_item :IN_PROGRESS, 'I'
  self.add_item :SUCCEEDED, 'S'
  self.add_item :FAILED, 'F'
  self.add_item :CANCELED, 'C'
end
