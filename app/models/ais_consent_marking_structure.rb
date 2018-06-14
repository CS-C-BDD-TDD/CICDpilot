class AisConsentMarkingStructure < ActiveRecord::Base
  belongs_to :stix_marking, primary_key: :stix_id, foreign_key: :stix_marking_id

  VALID_COLORS = %w(white green amber)
  VALID_CONSENTS = %w(none usg everyone)

  validates_presence_of :consent,:color
  validates_inclusion_of :consent, in: VALID_CONSENTS, message: "is an invalid consent value.  Valid values are #{VALID_CONSENTS.collect(&:to_s).join(', ')}"
  validates_inclusion_of :color, in: VALID_COLORS ,message: "is an invalid tlp color value.  Valid values are #{VALID_COLORS.collect(&:to_s).join(', ')}"
  validates_inclusion_of :proprietary, in: [true,false], message: "can't be blank"
  validate :proprietary_consent
  before_destroy :audit_ais_removal

  def audit_ais_removal 
      if self.stix_marking.remote_object.blank? 
        return true;
      end
      audit = Audit.basic
      audit.message = "AIS Consent Marking Structure removed from #{self.stix_marking.stix_id}"
      audit.audit_type = :ais_marking_destroy
      audit.item = self.stix_marking.remote_object
      audit.user = User.current_user
      self.stix_marking.remote_object.audits << audit
      return true;
  end

  def color=(color)
    return unless color.present?
    write_attribute(:color,color.to_s.downcase)
  end

  def consent=(consent)
    return unless consent.present?
    write_attribute(:consent,consent.to_s.downcase)
  end

  include Auditable
  include Guidable
  include Stixable
  include Transferable

  def self.ingest(uploader,marking,msobj)
    s = AisConsentMarkingStructure.new
    s.stix_marking_id = marking.stix_id
    s.stix_marking = marking
    s.set_guid
    s.stix_id = msobj.stix_id
    s.set_stix_id
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      s.stix_id = s.stix_id + Setting.READ_ONLY_EXT
      s.guid = s.guid + Setting.READ_ONLY_EXT
    end

    s.consent = msobj.consent
    s.color = msobj.color
    s.proprietary = msobj.proprietary

    s
  end

  private

  def proprietary_consent
    return unless self.proprietary.present? && self.consent.present?
    errors.add(:consent, "value must be \"EVERYONE\" when CISA_Proprietary is true") if self.proprietary && self.consent != 'everyone'
  end
  def submission_mechanism
    package = self.stix_marking.remote_object
    return if package.present? && package.is_ciscp
    errors.add(:submission_mechanism,"AIS Consent Marking must apply to a Stix Package") unless package.present?
    errors.add(:submission_mechanism,"AIS Consent Marking must include a Contributing Source") unless package.contributing_sources.present?
    errors.add(:submission_mechanism,"AIS Consent Marking must include a Submission Mechanism") unless package.submission_mechanism.present?
  end
end
