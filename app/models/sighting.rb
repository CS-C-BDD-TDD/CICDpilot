class Sighting < ActiveRecord::Base
  self.table_name = "stix_sightings"
  belongs_to :indicator, primary_key: :stix_id, foreign_key: :stix_indicator_id
  belongs_to :user, primary_key: :guid, foreign_key: :user_guid
  has_many :confidences, -> {reorder(is_official: :desc).order(stix_timestamp: :desc)},primary_key: :guid, as: :remote_object,dependent: :destroy

  accepts_nested_attributes_for :confidences, reject_if: proc {|attributes| attributes['value'].blank?}

  before_create :assign_current_user
  
  validates_presence_of :sighted_at 
  
  validate :validate_sighted_at

  include Auditable
  include Guidable
  include Ingestible
  include Serialized
  include Transferable

  def self.ingest(uploader, obj, parent = nil)
    x = Sighting.new
    HumanReview.adjust(obj, uploader)
    x.description = obj.description
    x.sighted_at = obj.stix_timestamp
    x.sighted_at_precision = obj.timestamp_precision
    x.stix_indicator_id = parent.stix_id

    x.confidences_attributes = obj.confidences.collect do |confidence|
      {
          value: confidence.value,
          description: confidence.description,
          source: confidence.source,
          stix_timestamp: confidence.stix_timestamp,
          from_file: true
      }
    end if obj.confidences.present?

    x
  end

  def confidence
    self.confidences.where(is_official: true).reorder(stix_timestamp: :desc).first.try(:value) || 'unknown'
  end

  def title
    if sighted_at.present?
      "Indicator sighted at #{sighted_at.strftime("%Y-%m-%e %H:%M")}"
    else
      "Indicator sighting"
    end
  end

  def assign_current_user
    self.user = User.current_user || User.new(username:'system')
  end

  def audit_create
    audit = Audit.basic
    
    sighting_title = ''

    sighting_title += self.sighted_at.to_s + ' | ' if self.sighted_at.present?
    sighting_title += self.description.to_s if self.description.present?

    audit.message = "Sighting '#{sighting_title}' added to Indicator"
    audit.message += " '#{self.indicator.stix_id}'" if self.indicator.present?
    audit.audit_type = :indicator_sighting_link

    other_audit = audit.dup
    other_audit.item = self
    self.audits << other_audit

    if self.indicator.present?
      obj_audit = audit.dup
      obj_audit.item = self.indicator
      self.indicator.audits << obj_audit
    end
  end

  def audit_destroy
    audit = Audit.basic
    
    sighting_title = ''

    sighting_title += self.sighted_at.to_s + ' | ' if self.sighted_at.present?
    sighting_title += self.description.to_s if self.description.present?

    audit.message = "Sighting '#{sighting_title}' removed from Indicator"
    audit.message += " '#{self.indicator.stix_id}'" if self.indicator.present?
    audit.audit_type = :indicator_sighting_unlink

    other_audit = audit.dup
    other_audit.item = self
    self.audits << other_audit

    if self.indicator.present?
      obj_audit = audit.dup
      obj_audit.item = self.indicator
      self.indicator.audits << obj_audit
    end
  end
  
  private 
    def validate_sighted_at
      return if self.sighted_at.blank?
      if self.sighted_at.future?
        errors.add(:sighted_at, "can not be future date")
      end
    end
end
