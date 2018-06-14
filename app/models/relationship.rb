class Relationship < ActiveRecord::Base
  include Guidable
  include Ingestible
  include Transferable
  self.table_name = "stix_related_objects"

  belongs_to :remote_src_object,polymorphic: true,primary_key: :guid, foreign_key: :remote_src_object_guid, foreign_type: :remote_src_object_type, touch: true
  belongs_to :remote_dest_object,polymorphic: true,primary_key: :guid, foreign_key: :remote_dest_object_guid,foreign_type: :remote_dest_object_type, touch: true

  has_many :confidences, -> {reorder(is_official: :desc).order(stix_timestamp: :desc)},primary_key: :guid, as: :remote_object,dependent: :destroy
  accepts_nested_attributes_for :confidences, reject_if: proc {|attributes| attributes['value'].blank?}

  validate :unique_relationship, on: :create
  validates_presence_of :remote_src_object
  validates_presence_of :remote_dest_object

  after_create :creation_audit_records
  after_update :update_audit_records
  before_destroy :destroy_audit_records

  # Note that the Relationship class uses guids, but we only have STIX ID's
  # during ingestion. So we're going to pre-generate the guids for the
  # objects that are related. In another oddity, relationships need access
  # to more objects, so the "parent" being passed in is actually a hash
  # containing those arguments.

  def self.ingest(uploader, obj, parent = nil)
    return nil if obj.indicator.nil? || parent.nil?

    i_real = parent[:parent_indicator]    # CIAP Parent Indicator
    ri_real = parent[:child_indicator]    # CIAP Child Indicator

    x = Relationship.new
    x.relationship_type = 'Indicator to Indicator'    # Placeholder

    # Handle the Destination side of the Relationship
    i_real.guid = SecureRandom.uuid if i_real.guid.nil?
    x.remote_dest_object_guid = i_real.guid
    x.remote_dest_object_type = 'Indicator'

    # Handle the Source side of the Relationship
    ri_real.guid = SecureRandom.uuid if ri_real.guid.nil?
    x.remote_src_object_guid = ri_real.guid
    x.remote_src_object_type = 'Indicator'
    x
  rescue
    nil
  end

  private

  def unique_relationship
    if Relationship.exists?({
                                 remote_src_object_guid: self.remote_src_object_guid,
                                 remote_dest_object_guid: self.remote_dest_object_guid}
    ) || Relationship.exists?({
                                   remote_src_object_guid: self.remote_dest_object_guid,
                                   remote_dest_object_guid: self.remote_src_object_guid}
    )
      errors.add(:relationship,'already exists')
    end

    if self.remote_dest_object_guid == self.remote_src_object_guid && self.remote_dest_object_type == self.remote_src_object_type
      errors.add(:relationship, 'cannot be self referencing')
    end
  end

  def creation_audit_records
    audit = Audit.basic
    audit.message = "Relationship between #{remote_src_object.title} and #{remote_dest_object.title} established"
    audit.audit_type = :relationship
    audit.item = self.remote_src_object
    self.remote_src_object.audits << audit
    dest_audit = audit.dup
    dest_audit.message = "Relationship between #{remote_dest_object.title} and #{remote_src_object.title} established"
    self.remote_dest_object.audits << dest_audit
  end

  def update_audit_records
    audit = Audit.basic
    audit.message = "Relationship between #{remote_src_object.title} and #{remote_dest_object.title} was updated"
    audit.audit_type = :relationship
    audit.item = self.remote_src_object
    self.remote_src_object.audits << audit
    dest_audit = audit.dup
    dest_audit.message = "Relationship between #{remote_dest_object.title} and #{remote_src_object.title} was updated"
    self.remote_dest_object.audits << dest_audit
  end

  def destroy_audit_records
    audit = Audit.basic
    audit.message = "Relationship between #{remote_src_object.title} and #{remote_dest_object.title} was deleted"
    audit.audit_type = :relationship
    audit.item = self.remote_src_object
    self.remote_src_object.audits << audit
    dest_audit = audit.dup
    dest_audit.message = "Relationship between #{remote_dest_object.title} and #{remote_src_object.title} was deleted"
    self.remote_dest_object.audits << dest_audit
  end
end
