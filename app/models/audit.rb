class Audit < ActiveRecord::Base
  self.table_name = 'audit_logs'
  belongs_to :item, polymorphic: true, foreign_key: :item_guid_audited, foreign_type: :item_type_audited, primary_key: :guid
  belongs_to :user, primary_key: :guid, foreign_key: :user_guid
  validates_presence_of :message,
                        :event_time,
                        :system_guid,
                        :item#,
                        #:user

  before_save :truncate_message

  include Guidable
  include Transferable

  # Override Transferable updated_at_field value
  def self.updated_at_field
    "event_time"
  end

  default_scope {order(event_time: :desc)}

  # We need this because we have the message as a varchar in oracle it only accepts 255 in length
  def truncate_message
    self.message = self.message[0..251] + "..." if self.message.present? && self.message.length > 255
  end

  def self.justification
    Thread.current[:justification]
  end

  def self.justification=(just)
    Thread.current[:justification] = just
  end

  def self.basic(item = nil, user=nil)
    user = user || User.current_user || User.new(guid:'00000000-0000-0000-0000-000000000000')

    audit = self.new(
      event_time: DateTime.now,
      user: user,
      system_guid: Setting.SYSTEM_GUID,
      justification: self.justification,
      item: item)
    return audit
  end
end
