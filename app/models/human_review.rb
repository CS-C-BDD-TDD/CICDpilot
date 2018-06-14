class HumanReview < ActiveRecord::Base
  include Auditable
  include Serialized
  
  attr_accessor :guid
  attr_accessor :data_errors

  STATUS = {'N' => 'Not Reviewed', 'A' => 'Approved', 'R' => 'Rejected', 'I' => 'In Progress', 'D' => 'Ready For Dissemination'}

  belongs_to :uploaded_file
  has_many :human_review_fields, dependent: :destroy
  accepts_nested_attributes_for :human_review_fields
  belongs_to :decided_by, class_name: 'User', foreign_key: :decided_by, primary_key: :guid

  validates_presence_of :uploaded_file, message: 'must associate an uploaded file'
  validate :valid_status

  attr_accessor :fields_count

  alias_method :user,:decided_by
  alias_method :user=,:decided_by=

  default_scope ->{order(created_at: :desc)}

  before_update :set_fields_on_accept
  after_update :ingest_approved_review

  def status=(status)
    status = status.to_s
    if status.length > 1
      if STATUS.values.collect(&:downcase).include?(status.downcase)
        write_attribute(:status,status[0].capitalize)
      end
    else
      write_attribute(:status,status.to_s.capitalize)
    end
  end

  def cleanup_pii
    hrf=HumanReviewField.where('human_review_id=?',self.id)
    pii=false
    hrf.each do |f|
      if f.is_changed
        pii=true
        f.object_field_original="PII Redacted"
        f.save
      end
    end
  end

  def add_error(msg)
    @data_errors << msg
  end

  # Returns a SHA2 hash for an object as a string.

  def self.calc_sha2_hash (obj)
    d = Digest::SHA2.new << obj.to_s
    d.to_s
  end

  # Creates a Human Review record and all of its associated field records.
  # Returns the HumanReview object if it has been successfully created.

  def self.load_human_review(xml, uploaded_file_id)
    hr = HumanReview.create(uploaded_file_id: uploaded_file_id, status: 'N')
    result = hr.load_human_review_fields(xml) if hr.present?

    if result == false
      hr.add_error("Error loading a Human Review field")
      hr.delete
    end
    return hr

  rescue
    if hr.present?
      hr.add_error("Exception encountered while loading Human Review data")
      hr.delete
      return hr
    end

    return nil
  end

  def self.adjust(obj, uploader)
  #  return unless obj.human_review_fields.present?
  #
  #  # Get prereqs to find a match between a human review field and an object
  # sha2 = HumanReview.calc_sha2_hash(obj)
  # hr = HumanReview.where(:uploaded_file_id => uploader.id).first

  # if hr
  #   lst = HumanReviewField.where(:human_review_id => hr.id).all
  #   lst.each do |hrf|
  #     if hrf.object_sha2 == sha2                   # Match the object on sha2
  #       obj.human_review_fields.each do |f|
  #         if f.to_s == hrf.object_field.to_s       # Match the field on name
  #           obj.send(f.to_s + '=', hrf.object_field_revised)
  #         end
  #       end
  #     end
  #   end
  # end
  end

  # Calls a STIX gem method to walk the XML and extract Human Review markings.

  def load_human_review_fields(xml)
    @data_errors = []
    ext = Stix::Stix111::HumanReviewExtractor.new(:rexml)
    lst = ext.extract(xml)
    if ext.errors.size > 0
      @data_errors = ext.errors
    else
      lst.each do |x|
        ingest_human_review_field(x)
      end
    end
  end

  private

    def valid_status
      unless STATUS.keys.include?(self.status)
        errors.add(:status, "Invalid status, must be 'N', 'A', 'I' or 'R'")
      end
    end

    def set_fields_on_accept
      return unless self.status_changed? && self.status == 'A'

      self.human_review_fields.each do |field|
        if field.object_field_revised.blank?
          field.object_field_revised = field.object_field_original
          field.save
        end
      end
      self.comp_human_review_fields_count = self.human_review_fields_count
    end

    def ingest_approved_review
      return unless self.status == 'A'

      uf = self.uploaded_file
      if uf.present?
         oi = uf.original_inputs.active.first    # Should only be one
         if oi.present?
           raw_xml = oi.utf8_raw_content
           ext = Stix::Stix111::HumanReviewExtractor.new(:rexml)
           revised_xml = ext.apply(raw_xml, self.human_review_fields)
           if revised_xml.nil?
             uf.update_attribute(:status, ActionStatus::FAILED)
             IngestUtilities.add_error(uf, "Human Review revision application failed at #{Time.now}")
           else
             oi.update_attribute(:raw_content, revised_xml)
             if uf.read_only
               uf.upload_data_file(revised_xml,  @user_id,
                               {read_only: true, human_review_approved: true})
             else
               uf.upload_data_file(revised_xml,  @user_id,
                               {overwrite: true, human_review_approved: true})
             end
             if uf.status == ActionStatus::FAILED
               IngestUtilities.add_error(uf, "Human Review full ingestion failed at #{Time.now}")
             else
               oi.update_attribute(:input_sub_category,
                                   OriginalInput::XML_HUMAN_REVIEW_COMPLETED)
               IngestUtilities.add_warning(uf, "Human Review full ingestion completed at #{Time.now}")

               AisStatisticLogger.debug("[human review][ingest_approved_review]: HUMAN Review completed creating AIS Statistics")
               AisStatistic.log_uploaded_file_result(uf)
             end
           end
         end
      end

      cleanup_pii
    end

    # Creates a Human Review Field row for a STIX-derived object. Returns TRUE
    # for success or FALSE otherwise.

    def ingest_human_review_field(obj)
      f = HumanReviewField.new
      f.human_review_id = self.id
      f.object_sha2 = obj.object_sha2
      f.object_uid = obj.object_uid
      f.object_type = obj.object_type
      f.object_field = obj.object_field
      f.object_field_original = obj.object_field_original
      f.save || (return false)

      return true
    end

end
