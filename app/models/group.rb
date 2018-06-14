class Group < ActiveRecord::Base
  has_many :group_permissions
  has_many :user_groups, dependent: :destroy
  has_many :permissions, through: :group_permissions, before_remove: :audit_permission_removal
  has_many :users, through: :user_groups, before_remove: :audit_user_removal

  validates_presence_of   :name, :description
  validates_uniqueness_of :name
  include Auditable
  include Guidable
  include Serialized

private

  def audit_permission_removal(item)
audit = Audit.basic
      audit.message = "Permission '#{item.display_name}' removed from group '#{self.name}'"
      audit.audit_type = :remove_permission
      group_audit = audit.dup
      group_audit.item = self
      self.audits << group_audit
      perm_audit = audit.dup
      perm_audit.item = item
      item.audits << perm_audit
      return
  end

  def audit_user_removal(item)
    audit = Audit.basic
    audit.message = "User '#{item.username}' removed from group '#{self.name}'"
    audit.audit_type = :ungroup
    group_audit = audit.dup
    group_audit.item = self
    self.audits << group_audit
    user_audit = audit.dup
    user_audit.item = item
    item.audits << user_audit
  end
end
