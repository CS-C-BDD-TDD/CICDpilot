class IsaMarkingStructure < ActiveRecord::Base
  belongs_to :stix_marking, primary_key: :stix_id, foreign_key: :stix_marking_id

  DEFAULTS = {re_custodian: 'USA.DHS.US-CERT', data_item_created_at: Time.now}

  before_save :set_defaults

  validate :valid_isa_attributes

  include Auditable
  include Guidable
  include Stixable
  include Transferable

  def self.ingest(uploader, marking, msobj)
    s = IsaMarkingStructure.new
    s.stix_marking_id = marking.stix_id
    s.set_guid
    s.stix_id = msobj.stix_id
    s.set_stix_id
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      s.stix_id = s.stix_id + Setting.READ_ONLY_EXT
      s.guid = s.guid + Setting.READ_ONLY_EXT
    end

    msobj.re_create_date_time.present? ?
        s.data_item_created_at = msobj.re_create_date_time :
        s.data_item_created_at = Time.now
    s.re_custodian = msobj.re_custodian
    s.re_originator = msobj.re_originator

    s
  end

  def responsible_entity
    str = ''
    str << "CUST:#{re_custodian}" unless re_custodian.nil?
    str << " ORIG:#{re_originator}" unless re_originator.nil?
    str
  end

  private

    def set_defaults
      self.re_custodian ||= 'USA.DHS.US-CERT'
      self.data_item_created_at ||= Time.now
    end

    def valid_isa_attributes
      klass = Stix::Native::IsaMarkingStructure

      if self.re_custodian.present?
        unless klass.validate_custodian(self.re_custodian)
          errors.add('Custodian',"'#{self.re_custodian}' is an invalid custodian organization")
        end
      end

      if self.re_originator.present?
        unless klass.validate_originator(self.re_originator)
          errors.add('Originator',"'#{self.re_originator}' is an invalid originator organization")
        end
      end

      errors.present?
    end

end
