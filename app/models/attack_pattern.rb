class AttackPattern < ActiveRecord::Base

  has_many :stix_markings, primary_key: :guid, as: :remote_object, dependent: :destroy
  accepts_nested_attributes_for :stix_markings, allow_destroy: true

  has_many :isa_marking_structures, primary_key: :stix_id, through: :stix_markings
  has_many :isa_assertion_structures, primary_key: :stix_id, through: :stix_markings

  has_many :ttp_attack_patterns, primary_key: :stix_id, foreign_key: :stix_attack_pattern_id
  has_many :ttps, through: :ttp_attack_patterns
  has_many :stix_packages, through: :ttps

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy
  
  belongs_to :created_by_user, class_name: 'User', primary_key: :guid, foreign_key: :created_by_user_guid
  belongs_to :updated_by_user, class_name: 'User', primary_key: :guid, foreign_key: :updated_by_user_guid
  belongs_to :created_by_organization, class_name: 'Organization', primary_key: :guid, foreign_key: :created_by_organization_guid
  belongs_to :updated_by_organization, class_name: 'Organization', primary_key: :guid, foreign_key: :updated_by_organization_guid

  def description=(value)
    if value.present?
      write_attribute(:description, value)
      write_attribute(:description_normalized, value.strip[0..254].downcase)
    else
      write_attribute(:description, nil)
      write_attribute(:description_normalized, nil)
    end
  end

  include AcsDefault
  include Auditable
  include Guidable
  include Stixable
  include Ingestible
  include Serialized
  include ClassifiedObject
  include Transferable

  CLASSIFICATION_CONTAINED_BY = [:ttps]

  def self.ingest(uploader, obj, parent = nil)
    x = AttackPattern.find_by_stix_id(obj.stix_id)
    matched = "stix_id"
    unless x
      if obj.capec_id
        x = AttackPattern.find_by_capec_id(obj.capec_id)
        matched = "capec_id"
      elsif obj.title.present? || obj.description.present?
        x = AttackPattern.where(:title=>obj.title,:description_normalized=>obj.description.downcase).first
        matched = "title/description"
      else
        IngestUtilities.add_warning(uploader, "WARNING: Skipping Blank Attack Pattern")
        return nil
      end
    end
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      if matched == "stix_id"
        IngestUtilities.add_warning(uploader, "Attack Pattern of #{obj.stix_id} already exists.  Skipping.  Select overwrite to add")
      end
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      if !obj.stix_id.nil?
        x = AttackPattern.find_by_stix_id(obj.stix_id + Setting.READ_ONLY_EXT)
      end
      unless x
        if obj.capec_id
          x = AttackPattern.find_by_capec_id(obj.capec_id)
        else
          x = AttackPattern.where(:title=>obj.title,:description_normalized=>obj.description.downcase).first
        end
      end
    end

    if x.present?
      x.stix_markings.destroy_all
      obj.stix_id = x.stix_id if obj.stix_id.nil?
    end

    if x.present? && (uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite))
      x.destroy
      x = nil
    end

    x ||= AttackPattern.new

    x.title = obj.title
    x.description = obj.description
    x.capec_id = obj.capec_id

    if (uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)) && !obj.stix_id.nil?
      x.stix_id = obj.stix_id + Setting.READ_ONLY_EXT
      if (defined? obj.guid)  
        x.guid = obj.guid + Setting.READ_ONLY_EXT
      else 
        x.guid = SecureRandom.uuid + Setting.READ_ONLY_EXT
      end
    else 
      x.stix_id = obj.stix_id
    end
    x.stix_timestamp = obj.respond_to?(:stix_timestamp) ? obj.stix_timestamp : nil

    unless parent.nil?
      x.created_by_user_guid = parent.guid
      x.created_by_organization_guid = parent.organization_guid
      x.updated_by_user_guid = parent.guid
      x.updated_by_organization_guid = parent.organization_guid
    end

    x.read_only = uploader.read_only

    x
  rescue
    IngestUtilities.add_warning(uploader, "Failed to build Attack Pattern (#{obj.stix_id})")
    x
  end

  def set_controlled_structure(sm, ttp_id = nil)
    if sm.present?
      ttp_id ||= self.ttp_ids.first

      if ttp_id.blank? && self.ttps.present?
        ttp_id = self.ttps.first.stix_id
      end
      sm.controlled_structure =
          "//stix:TTP[@id='#{ttp_id}']//ttp:Attack_Pattern"
      xpath_segments = []
      xpath_segments << (self.title.blank? ? 'not(ttp:Title)' :
          "ttp:Title='#{self.title}'")
      xpath_segments << (self.description.blank? ? 'not(ttp:Description)' :
          "ttp:Description='#{self.description}'")
      xpath_segments << (self.capec_id.blank? ? 'not(@capec_id)' :
          "@capec_id='#{self.capec_id}'")
      sm.controlled_structure +=
          "[#{ xpath_segments.join(' and ') }]/"
      if sm.remote_object_field.present?
        case sm.remote_object_field
          when 'title'
            sm.controlled_structure +=
                "ttp:Title/"
          when 'description'
            sm.controlled_structure +=
                "ttp:Description/"
          when 'capec_id'
            sm.controlled_structure +=
                "@capec_id"
            return # We are done because "capec_id" is an XML attribute.
          else
            sm.controlled_structure = nil
            return
        end
      end
      sm.controlled_structure += 'descendant-or-self::node()'
      sm.controlled_structure += " | #{sm.controlled_structure}/@*"
    end
  end

  private

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :title
    string :title
    text :description
    string :description
    text :capec_id
    string :capec_id
    text :guid, as: :text_exact
    string :guid
    time :updated_at, stored: false
    time :created_at, stored: false

  end

end
