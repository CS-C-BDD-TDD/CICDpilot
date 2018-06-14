# to include this module, you need to implement:
#  * audits as an assoication
#  * model_name.human - Set custom through locales
module Auditable extend ActiveSupport::Concern
  included do |base|
    has_many :audits, -> {where(item_type_audited: base.to_s)}, foreign_key: :item_guid_audited, primary_key: :guid
    after_create :audit_create

    def audit_create
      audit = Audit.basic(self)

      audit.message = "#{self.class.model_name.human} created"
      # except needs to come BEFORE hmap
      sanitized_changes = Auditable.sanitize_changes(self.changes, self.class)
      audit.details = sanitized_changes.hmap{|k,v|{k=>v[1]}}.to_s
      audit.audit_type = :create
      self.audits << audit
      return
    end

    after_update :audit_update
    def audit_update
      # return if no changes to indicator directly
      return if self.changes.except("updated_at").length == 0
      audit = Audit.basic(self)

      clazz = self.class if self.class
      model_name = clazz.model_name if clazz
      class_name = model_name.human if model_name
      
      audit.message = "Updated #{class_name}"
      sanitized_changes = Auditable.sanitize_changes(self.changes, self.class)
      audit.details = sanitized_changes.to_s
      audit.audit_type = :update
      self.audits << audit
      return
    end
    after_destroy :audit_destroy
    def audit_destroy
      audit = Audit.basic(self)
      audit.message = "#{self.class.model_name.human} deleted"
      audit.audit_type = :delete
      self.audits << audit
      return
    end

    def audit_obj_removal(item)
      obj = item
      parent = self

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
      audit.message = "#{obj.class.to_s.tableize.singularize.titleize} '#{obj_id}' removed from #{parent.class.to_s.tableize.singularize.titleize} '#{parent_id}'"
      audit.audit_type = "#{parent.class.to_s.tableize.singularize}_#{obj.class.to_s.tableize.singularize}_unlink"

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

  end

  module ClassMethods
  end

  module Instrumentation extend ActiveSupport::Concern
    class Changes
      def initialize(changes)
        @changes = changes
        @sanitized_changes = Auditable.sanitize_changes(changes)
      end

      def to_s
        @sanitized_changes.to_s
      end
    end

    included do |base|
      before_create :before_create_event
      after_create :after_create_event
      before_update :before_update_event
      after_update :after_update_event
      before_destroy :before_destroy_event
      after_destroy :after_destroy_event

      def will_create?

      end

      def will_update?

      end

      def will_destroy?

      end

      def create_message
        self.errors.present? ? 'create_error' : 'create'
      end

      def update_message
        self.errors.present? ? 'update_error' : 'update'
      end

      def destroy_message
        self.errors.present? ? 'destroy_error' : 'destroy'
      end

      def before_create_event
        record_lifecycle_ids
        # LifecycleLogger.info("[#{self.class}][created] valid: #{self.valid?}")
      end

      def before_update_event
        record_lifecycle_ids
        # LifecycleLogger.info("[#{self.class}][updated] valid: #{self.valid?}")
      end

      def before_destroy_event
        record_lifecycle_ids
        # LifecycleLogger.info("[#{self.class}][destroyed] valid: #{self.valid?}")
      end

      def record_lifecycle_ids
        if self.respond_to?(:guid)
          @_guid = self.guid
        else
          @_guid = 'MISSING'
        end

        if self.respond_to?(:id)
          @_id = self.id
        else
          @_id = 'MISSING'
        end
      end

      def lifecycle_changes
        begin
          Changes.new(self.changes).to_json
        rescue Encoding::UndefinedConversionError
          # if any of the data members are binary, they will not convert to json
          h = Auditable.remove_binary_changes(self.changes)
          Changes.new(h).to_json
        end
      end

      def after_create_event
        LifecycleLogger.debug("[#{self.class}][#{create_message}] {guid: #{@_guid},class: #{self.class}}")
        LifecycleLogger.debug("[#{self.class}][#{create_message}] changes: #{lifecycle_changes}, errors: #{self.errors.messages.to_json}")
      end

      def after_update_event
        LifecycleLogger.debug("[#{self.class}][#{update_message}] {guid: #{@_guid},class: #{self.class}}")
        LifecycleLogger.debug("[#{self.class}][#{update_message}] guid: #{@_guid}, changes: #{lifecycle_changes}, errors: #{self.errors.messages.to_json}")
      end

      def after_destroy_event
        LifecycleLogger.debug("[#{self.class}][#{destroy_message}] {guid: #{@_guid},class: #{self.class}}")
        LifecycleLogger.debug("[#{self.class}][#{destroy_message}] guid: #{@_guid},changes: #{lifecycle_changes}, errors: #{self.errors.messages.to_json}")
      end

    end
  end

protected # Can be seen by internal modules here

  def self.remove_binary_changes(changes)
    h = Hash.new
    changes.each do |key, arr|
      h[key] = Array.new
      (0..1).each do |i|
        if arr[i].try(:encoding).try(:to_s) == "ASCII-8BIT"
          h[key][i] = "BINARY"
        else
          h[key][i] = arr[i]
        end
      end
    end
    return h
  end

  def self.sanitize_changes(changes, type = nil)
    h = Hash.new
    changes.each do |key, arr|
      next if key.to_s == "created_at"
      next if key.to_s == "updated_at"
      next if key.to_s == "from_normalized"
      next if key.to_s == "reply_to_normalized"
      next if key.to_s == "sender_normalized"
      if (["password_salt","password_hash","api_key_secret_encrypted","from_raw","raw_body","raw_header","reply_to_raw","sender_raw","x_mailer"].include?(key.to_s) ||
          type == StixPackage && ["description","short_description"].include?(key.to_s))
        h[key] = Array.new
        (0..1).each do |i|
          if arr[i].present?
            h[key][i] = "*****"
          else
            h[key][i] = arr[i]
          end
        end
      else
        h[key] = arr
      end
    end
    return h
  end

end
