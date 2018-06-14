class Gfi < ActiveRecord::Base

  self.table_name = "gfis"

  include Auditable
  include Guidable
  include Serialized

  belongs_to :object, polymorphic: true, primary_key: :cybox_object_id, foreign_key: :remote_object_id, foreign_type: :remote_object_type, touch: true

  belongs_to :address
  belongs_to :domain
  belongs_to :email_message
  belongs_to :cybox_file
  belongs_to :dns_record

  # you need to override the auditable methods because you want the audit records in the remote object not the gfi field
  def audit_create
    audit = Audit.basic(self)
    audit.message = "#{self.class.model_name.human} created"
    # except needs to come BEFORE hmap
    sanitized_changes = Auditable.sanitize_changes(self.changes, self.class)
    audit.details = sanitized_changes.hmap{|k,v|{k=>v[1]}}.to_s
    audit.audit_type = :create
    audit.item = self.object
    if self.object.present?
    	self.object.audits << audit
    end
    return
  end

  def audit_update
    # return if no changes to gfi directly
    return if self.changes.except("updated_at").length == 0
    audit = Audit.basic(self)

    clazz = self.class if self.class
    model_name = clazz.model_name if clazz
    class_name = model_name.human if model_name
    
    audit.message = "Updated #{class_name}"
    sanitized_changes = Auditable.sanitize_changes(self.changes, self.class)
    audit.details = sanitized_changes.to_s
    audit.audit_type = :update
    audit.item = self.object
    if self.object.present?
    	self.object.audits << audit
    end
    return
  end

  def audit_destroy
    audit = Audit.basic(self)
    audit.message = "#{self.class.model_name.human} deleted"
    audit.audit_type = :delete
    audit.item = self.object
    if self.object.present?
    	self.object.audits << audit
    end
    return
  end

end
