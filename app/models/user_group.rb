class UserGroup < ActiveRecord::Base
  self.table_name = "users_groups"

  belongs_to :group
  belongs_to :user, foreign_key: :user_guid, primary_key: :guid

  include Guidable

  after_create :audit_ug_save
  def audit_ug_save
    if (self.group.present? &&
        self.user.present?)
      audit = Audit.basic
      audit.message = "User '#{self.user.username}' added to group '#{self.group.name}'"
      audit.audit_type = :group
      group_audit = audit.dup
      group_audit.item = self.group
      self.group.audits << group_audit
      user_audit = audit.dup
      user_audit.item = self.user
      self.user.audits << user_audit
      return
    end
  end
end
