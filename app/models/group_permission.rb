class GroupPermission < ActiveRecord::Base
  self.table_name = "groups_permissions"

  belongs_to :group
  belongs_to :permission

  include Guidable
  after_create :audit_gp_save
  def audit_gp_save
    if (self.group.present? &&
        self.permission.present?)
      audit = Audit.basic
      audit.message = "Permission '#{self.permission.display_name}' added to group '#{self.group.name}'"
      audit.audit_type = :permission
      group_audit = audit.dup
      group_audit.item = self.group
      self.group.audits << group_audit
      perm_audit = audit.dup
      perm_audit.item = self.permission
      self.permission.audits << perm_audit
      return
    end
  end
end
