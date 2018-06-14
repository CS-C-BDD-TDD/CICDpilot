class CourseOfAction < ActiveRecord::Base
  include AcsDefault
  include Transferable
  
  self.table_name = "course_of_actions"

  #Markings
  has_many :stix_markings, primary_key: :guid, as: :remote_object, dependent: :destroy
  accepts_nested_attributes_for :stix_markings, allow_destroy: true
  
  #suggested_coas
  has_many :indicators_course_of_actions, primary_key: :stix_id, foreign_key: :course_of_action_id
  has_many :indicators, through: :indicators_course_of_actions, before_remove: :audit_indicator_removal
  
  #packages
  has_many :packages_course_of_actions, primary_key: :stix_id, foreign_key: :course_of_action_id
  has_many :stix_packages, through: :packages_course_of_actions, before_remove: :audit_package_removal

  #Parameter Observables
  has_many :observables, through: :indicators
  #accepts_nested_attributes_for :parameter_observables
  has_many :parameter_observables, ->{reorder(created_at: :asc)}, primary_key: :stix_id, foreign_key: :stix_course_of_action_id, dependent: :destroy

  has_many :exploit_target_course_of_actions, primary_key: :stix_id, foreign_key: :stix_course_of_action_id, dependent: :destroy
  has_many :exploit_targets, through: :exploit_target_course_of_actions
  
  belongs_to :created_by_user, class_name: 'User', primary_key: :guid, foreign_key: :created_by_user_guid
  belongs_to :updated_by_user, class_name: 'User', primary_key: :guid, foreign_key: :updated_by_user_guid
  belongs_to :created_by_organization, class_name: 'Organization', primary_key: :guid, foreign_key: :created_by_organization_guid
  belongs_to :updated_by_organization, class_name: 'Organization', primary_key: :guid, foreign_key: :updated_by_organization_guid

  has_many :isa_marking_structures, primary_key: :stix_id, through: :stix_markings
  has_many :isa_assertion_structures, primary_key: :stix_id, through: :stix_markings
  belongs_to :acs_set, primary_key: :guid

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  before_save :set_controlled_structures

  validates_presence_of :title
  
# Trickles down the disseminated feed value to all of the associated objects
def trickledown_feed
  begin
    associations = ["observables", "parameter_observables"]
    associations.each do |a|
      object = self.send a
      if object.present? && self.feeds.present?
        object.each do |x| 
          x.update_column(:feeds, self.feeds) 
          x.try(:trickledown_feed)
        end 
      end
    end
  rescue Exception => e
    ex_msg = "Exception during trickledown_feed on: " + self.class.name    
    ExceptionLogger.debug("#{ex_msg}" + ". #{e.to_s}")
  end
end     
  
  def indicator_stix_ids=(stix_ids)
    self.indicator_ids = Indicator.where(stix_id: stix_ids).pluck(:id)
  end
  
  def stix_package_stix_ids=(stix_ids)
    self.stix_package_ids = StixPackage.where(stix_id: stix_ids).pluck(:id)
  end

  def description=(value)
    if value.present?
      write_attribute(:description, value)
      write_attribute(:description_normalized, value.strip[0..254])
    else
      write_attribute(:description, nil)
      write_attribute(:description_normalized, nil)
    end
  end

  include Auditable
  include Guidable
  include Stixable
  include Ingestible
  include Serialized
  include ClassifiedObject

  def self.ingest(uploader, obj, parent = nil)
    coa = CourseOfAction.find_by_stix_id(obj.stix_id)
    if coa.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "Course of Action of #{obj.stix_id} already exists.  Select overwrite to add")
      return false
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      if !obj.stix_id.nil?
        coa = CourseOfAction.find_by_stix_id(obj.stix_id + Setting.READ_ONLY_EXT)
      end
    end
    
    if coa.present?
      coa.stix_markings.destroy_all
      coa.acs_set_id = nil
    end

    if coa.present? && (uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite))
      coa.destroy
      coa = nil
    end
    
    coa ||= CourseOfAction.new
    coa.description = obj.description
    # If there is no title included, use the course of action ID
    coa.title = obj.title || obj.stix_id
    if (uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)) && !obj.stix_id.nil?
      coa.stix_id = obj.stix_id + Setting.READ_ONLY_EXT
      if  (defined? obj.guid) 
        coa.guid = obj.guid + Setting.READ_ONLY_EXT
      else 
        coa.guid = SecureRandom.uuid + Setting.READ_ONLY_EXT
      end
    else 
      coa.stix_id = obj.stix_id
    end
    coa.stix_timestamp = obj.stix_timestamp

    unless parent.nil?
      coa.created_by_user_guid = parent.guid
      coa.created_by_organization_guid = parent.organization_guid
      coa.updated_by_user_guid = parent.guid
      coa.updated_by_organization_guid = parent.organization_guid
    end
    coa.read_only = uploader.read_only

    coa
  end

  def set_controlled_structures
    if self.stix_markings.present?
      self.stix_markings.each { |sm| set_controlled_structure(sm) }
    end
  end

  def set_controlled_structure(sm)
    if sm.present?
      sm.controlled_structure =
          "//stix:Course_Of_Action[@id='#{self.stix_id}']/"
      if sm.remote_object_field.present?
        case sm.remote_object_field
          when 'title'
            sm.controlled_structure +=
                'coa:Title/'
          when 'description'
            sm.controlled_structure +=
                'coa:Description/'
          else
            sm.controlled_structure = nil
            return
        end
      end
      sm.controlled_structure += 'descendant-or-self::node()'
      sm.controlled_structure += "| #{sm.controlled_structure}/@*"
    end
   end
  
  CLASSIFICATION_CONTAINED_BY = [:indicators, :stix_packages]

private

  def audit_indicator_removal(item)
    audit = Audit.basic
    audit.message = "Indicator '#{item.title}' removed course of action '#{self.title}'"
    audit.audit_type = :indicator_course_of_action_unlink
    ind_audit = audit.dup
    ind_audit.item = item
    item.audits << ind_audit
    ta_audit = audit.dup
    ta_audit.item = self
    self.audits << ta_audit
  end
  
  def audit_package_removal(item)
    audit = Audit.basic
    audit.message = "Package '#{item.title}' removed by course of action '#{self.title}'"
    audit.audit_type = :stix_package_course_of_action_unlink
    pkg_audit = audit.dup
    pkg_audit.item = item
    item.audits << pkg_audit
    coa_audit = audit.dup
    coa_audit.item = self
    self.audits << coa_audit
  end

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :title
    string :title
    text :description
    string :description
    text :description_normalized
    string :description_normalized
    text :stix_id, as: :text_exact
    string :stix_id
    text :guid, as: :text_exactm
    time :updated_at, stored: false
    time :created_at, stored: false

  end
end
  
