class Confidence < ActiveRecord::Base
  self.table_name = 'stix_confidences'

  VALID_CONFIDENCES = ['Unknown', 'Low', 'Medium', 'High']

  CONFIDENCE_MAP = {unknown: 0, low: 1, medium: 2, high: 3}

  belongs_to :indicator, primary_key: :guid, foreign_type: :remote_object_type, foreign_key: :remote_object_id, touch: true, class_name: 'Indicator'
  belongs_to :relationship, primary_key: :guid, foreign_key: :remote_object_id, foreign_type: :remote_object_type, touch: true, class_name: 'Relationship'
  belongs_to :remote_object,  primary_key: :guid, foreign_key: :remote_object_id, foreign_type: :remote_object_type, touch: true, polymorphic:true
  belongs_to :user, primary_key: :guid, foreign_key: :user_guid

  validate :valid_confidence

  default_scope {order(is_official: :desc).order(stix_timestamp: :desc)}

  before_create :assign_current_user
  before_create :assign_stix_timestamp
  after_create :add_audit_history_to_object

  def value=(value)
    value = 'Unknown' if value.blank?

    write_attribute(:value, value.downcase)
    write_attribute(:confidence_num,CONFIDENCE_MAP[value.downcase.to_sym])
  end

  def valid_confidence
    if value_changed?
      # confidence not yet required
      #if confidence.blank?
      #  errors.add(:confidence, "You must set a confidence level for this indicator")
      #end

      # Check if confidence set is a valid value
      unless VALID_CONFIDENCES.map{|c|c.upcase}.include?(value.upcase)
        errors.add(:value, "#{self.value} is not a valid confidence")
      end
    end
  end

  def assign_current_user
    self.user = User.current_user || User.new(username:'system')
  end

  def add_audit_history_to_object
    if self.remote_object_type == 'Indicator'
      audit = Audit.basic
      audit.message = "Confidence '#{self.value}' added to indicator '#{self.indicator.try(:title) || self.indicator.stix_id}'"
      audit.audit_type = :confidence
      audit.item = self.indicator
      self.indicator.audits << audit

      if self.indicator.observables.present?
        indicator.observables.each do |o|
          audit = Audit.basic
          audit.message = "Confidence '#{self.value}' added to indicator '#{self.indicator.try(:title) || self.indicator.stix_id}'"
          audit.audit_type = :confidence
          audit.item = o.object
          unless o.object.nil?
            o.object.audits << audit
          end
        end
      end
    end
  end

  def assign_stix_timestamp
    self.stix_timestamp ||= self.created_at
  end
  
  include Guidable
  include Transferable

  # Override Transferable updated_at_field value
  def self.updated_at_field
    "created_at"
  end
end
