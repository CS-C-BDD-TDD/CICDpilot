class CyboxMutex < ActiveRecord::Base

  module Naming
    def display_name
      return name
    end

    def display_class_name
	    "Mutex"
    end
  end

  self.table_name = "cybox_mutexes"

  include Auditable
  include CyboxMutex::Naming
  include Guidable
  include Cyboxable
  include Ingestible
  include AcsDefault
  include Serialized
  include Transferable
  
  has_many :observables, -> { where remote_object_type: 'CyboxMutex' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, dependent: :destroy
  has_many :indicators, through: :observables
  has_many :ind_course_of_actions, through: :indicators, class_name: 'CourseOfAction', source: :course_of_actions

  has_many :parameter_observables, -> { where remote_object_type: 'CyboxMutex' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
  has_many :course_of_actions, through: :parameter_observables
  
  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  validates_presence_of :name
  validates_uniqueness_of :name, :message => "cannot match a Mutex already in the system", unless: :duplication_needed?
  validate :immutable_name, on: :update
  after_commit :set_observable_value_on_indicator

  def stix_packages
    packages = []

    packages |= self.course_of_actions.collect(&:stix_packages).flatten if self.course_of_actions.present?
    packages |= self.indicators.collect(&:stix_packages).flatten if self.indicators.present?

    packages
  end

  def self.ingest(uploader, obj, parent = nil)
    x = CyboxMutex.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "Mutex of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x = obj.cybox_object_id.nil? ? nil : CyboxMutex.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
      if x.present? 
        x.destroy
        x = nil
      end
    end

    if x.present?
      # Destroy all existing STIX markings to be re-ingested.
      x.stix_markings.destroy_all
    end

    x ||= CyboxMutex.new
    HumanReview.adjust(obj, uploader)
    #x.apply_condition = obj.apply_condition
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end
    x.name = obj.name
    x.name_condition = obj.name_condition
    x.read_only = uploader.read_only
    x
  end

  def duplication_needed?
    cybox_object_id && cybox_object_id.include?(Setting.READ_ONLY_EXT)
  end

  def set_cybox_hash
    write_attribute(:cybox_hash, CyboxHash.generate(self.name))
  end

  def repl_params
    {
      name: name,
      cybox_object_id: cybox_object_id,
      guid: guid
    }
  end

  def set_controlled_structures
    if self.stix_markings.present?
      self.stix_markings.each { |sm| set_controlled_structure(sm) }
    end
  end

  def set_controlled_structure(sm)
    if sm.present?
      sm.controlled_structure =
          "//cybox:Object[@id='#{self.cybox_object_id}']/"
      sm.controlled_structure += 'descendant-or-self::node()'
      sm.controlled_structure += "| #{sm.controlled_structure}/@*"
    end
  end

  def total_sightings
    cnt = 0
    cnt = indicators.collect{|ind| ind.sightings.size}.sum
    return cnt
  end

  private

  def set_observable_value_on_indicator
    self.indicators.each do |indicator|
      indicator.set_observable_value
    end
  end

  def immutable_name
    errors.add(:name, "cannot be modified") if self.changes.include?('name')
  end

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :name
    string :name
    text :name_condition
    string :name_condition
    time :created_at, stored: false
    text :cybox_object_id, as: :text_exact
    string :cybox_object_id
    string :portion_marking, stored: false

    time :updated_at, stored: false

    text :guid, as: :text_exactm
  end
end
