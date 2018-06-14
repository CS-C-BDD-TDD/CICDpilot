class BadgeStatus < ActiveRecord::Base
  self.table_name = "badge_statuses"
  
  include Auditable
  include Guidable
  include Serialized
  include Transferable

  belongs_to :remote_object, polymorphic: true, primary_key: :guid, foreign_key: :remote_object_id, foreign_type: :remote_object_type

  before_create :audit_badge_create_on_object
  before_update :audit_badge_update_on_object
  before_destroy :audit_badge_destroy_on_object

  validates :badge_name, length: { minimum: 1 }

  def audit_badge_create_on_object
    audit = Audit.basic
    audit.item = self.remote_object
    audit.audit_type = :badge_added
    audit.message = "Badge name '#{self.badge_name}' with status '#{self.badge_status}' added"
    self.remote_object.audits << audit
  end

  def audit_badge_update_on_object
    audit = Audit.basic
    audit.item = self.remote_object
    audit.audit_type = :badge_updated
    audit.message = "Badge name '#{self.badge_name_was}' with status '#{self.badge_status_was}' updated to name '#{self.badge_name}' with status '#{self.badge_status}'"
    self.remote_object.audits << audit
  end

  def audit_badge_destroy_on_object
    audit = Audit.basic
    audit.item = self.remote_object
    audit.audit_type = :badge_deleted
    audit.message = "Badge name '#{self.badge_name}' with status '#{self.badge_status}' deleted"
    self.remote_object.audits << audit
  end
end
