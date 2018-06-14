module LinkingTableCommon extend ActiveSupport::Concern
  included do |base|
    after_create :audit_obj_save
  end

  def audit_obj_save
    obj = self.obj
    parent = self.parent

    obj_id = ""
    if obj.present? 
      if obj.respond_to?(:stix_id)
        obj_id = obj.stix_id.to_s
      elsif obj.respond_to?(:cybox_object_id)
        obj_id = obj.cybox_object_id.to_s
      elsif obj.respond_to?(:guid)
        obj_id = obj.guid.to_s
      end
    end

    parent_id = ""
    if parent.present? 
      if parent.respond_to?(:stix_id)
        parent_id = parent.stix_id.to_s
      elsif parent.respond_to?(:cybox_object_id)
        parent_id = parent.cybox_object_id.to_s
      elsif parent.respond_to?(:guid)
        parent_id = parent.guid.to_s
      end
    end
    
    audit = Audit.basic
    audit.message = "#{obj.class.to_s.tableize.singularize.titleize} '#{obj_id}' added to #{parent.class.to_s.tableize.singularize.titleize} '#{parent_id}'"
    audit.audit_type = "#{parent.class.to_s.tableize.singularize}_#{obj.class.to_s.tableize.singularize}_link"

    if obj.present?
      obj_audit = audit.dup
      obj_audit.item = obj
      obj.audits << obj_audit
    end

    if parent.present?
      parent_audit = audit.dup
      parent_audit.item = parent
      parent.audits << parent_audit
    end
  end

  module ClassMethods
  end

end
