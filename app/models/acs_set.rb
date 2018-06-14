class AcsSet < ActiveRecord::Base
  include Guidable
  include Stixable
  include Auditable
  include Serialized
  include Transferable

  alias_attribute :title,:name

  has_many :stix_markings, primary_key: :guid, as: :remote_object, dependent: :destroy
  has_many :isa_assertion_structures, primary_key: :stix_id, through: :stix_markings, dependent: :destroy
  has_many :acs_sets_organizations, primary_key: :guid, dependent: :destroy
  has_many :organizations, through: :acs_sets_organizations

  has_many :indicators, primary_key: :guid
  has_many :stix_packages, primary_key: :guid
  has_many :threat_actors, primary_key: :guid
  has_many :course_of_actions, primary_key: :guid
  has_many :ttps, primary_key: :guid
  has_many :exploit_targets, primary_key: :guid
  
  before_save :set_color

  accepts_nested_attributes_for :stix_markings
  accepts_nested_attributes_for :acs_sets_organizations, reject_if: :org_exists

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :stix_markings

  after_save :set_portion_marking

  scope :for_org, ->(organization) {acs_orgs = AcsSetsOrganization.arel_table;joins("left join acs_sets_organizations ON acs_sets_organizations.acs_set_id = acs_sets.guid").
      where(acs_orgs[:organization_id].eq(nil).or(acs_orgs[:organization_id].eq(organization.guid)))}

  def set_portion_marking
    return unless self.respond_to?(:portion_marking)
    object_classification = self.stix_markings.select {|s| s.remote_object_field.blank? }.collect(&:isa_assertion_structure).compact.first
    if object_classification.present?
      object_classification = object_classification.cs_classification
      self.portion_marking = object_classification
      self.update_columns({portion_marking: object_classification})
      self.reload
    end
  end

  private

  def set_color
    self.stix_markings.each do |stix_marking|
      next unless stix_marking.tlp_marking_structure.present?
      write_attribute(:color,stix_marking.tlp_marking_structure.color)
      return
    end
  end

  def hash_from_changes(changes)
    new_hash = {}
    changes.each_pair {|k,v| new_hash.merge!(k => v.second) }
    new_hash
  end

  def org_exists(attributes)
    return false unless self.id.present?
    set = AcsSetsOrganization.where(acs_set_id: self.guid).where(organization_id: attributes[:organization_id])
    if set.present? && set.exists? && attributes[:destroy].present?
      set.first.destroy
      return true
    elsif set.exists?
      return true
    end
    attributes.delete(:destroy)
    false
  end
end
