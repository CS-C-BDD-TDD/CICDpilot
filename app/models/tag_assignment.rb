class TagAssignment < ActiveRecord::Base
  belongs_to :user,
             foreign_key: :user_guid,
             primary_key: :guid

  belongs_to :remote_object,
             polymorphic: true,
             primary_key: :guid,
             touch: true,
             foreign_key: :remote_object_guid

  belongs_to :system_tag,
             foreign_key: :tag_guid,
             primary_key: :guid
  belongs_to :user_tag,
             foreign_key: :tag_guid,
             primary_key: :guid

  include Guidable
  include Transferable

  # Override Transferable updated_at_field value
  def self.updated_at_field
    "created_at"
  end

  after_save :audit_save
  def audit_save
    if ((self.system_tag.present? || self.user_tag.present?) &&
        self.remote_object.present? &&
        self.changes.include?("tag_guid") &&
        self.changes.include?("remote_object_guid"))
      audit = Audit.basic
      audit.message = "Tagged #{self.remote_object.class.model_name.human} with '#{(self.system_tag||self.user_tag).name}'"
      audit.audit_type = :tag
      tag_audit = audit.dup
      tag_audit.item = self.system_tag || self.user_tag

      if self.system_tag.present?
        self.system_tag.audits << tag_audit
      end
      if self.user_tag.present?
        self.user_tag.audits << tag_audit
      end

      obj_audit = audit.dup
      obj_audit.item = self.remote_object
      self.remote_object.audits << obj_audit if self.remote_object.respond_to? :audits
      return
    end
  end

# This code is duplicated in TagAssignment.rb
# Leaving this in for now, as there were other associations where the after_destroy was NOT called.  If that happens for any reason, this can be used instead.
# Note: I like the message on TaggAssignment.rb's audit_tag_removal better, it puts the indicator title
=begin
  after_destroy :audit_destroy
  def audit_destroy
    if ( (self.system_tag.present? || self.user_tag.present?) &&
        self.remote_object.present?)
      audit = Audit.basic
      audit.message = "Tag removed '#{(self.system_tag||self.user_tag).name}' from #{self.remote_object.class.model_name.human}"
      audit.audit_type = :untag
      tag_audit = audit.dup
      tag_audit.item = self.system_tag || self.user_tag

      if self.system_tag.present?
        self.system_tag.audits << tag_audit
      end
      if self.user_tag.present?
        self.user_tag.audits << tag_audit
      end

      obj_audit = audit.dup
      obj_audit.item = self.remote_object
      self.remote_object.audits << obj_audit if self.remote_object.respond_to? :audits
      return
    end
  end
=end
end
