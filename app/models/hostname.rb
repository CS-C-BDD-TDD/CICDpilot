class Hostname < ActiveRecord::Base
  require 'csv'
  
  module RawAttribute
    module Writers
      def hostname_raw=(value)
        write_attribute(:hostname_raw, nil)
        write_attribute(:hostname_normalized, nil)
        unless value.nil?
          write_attribute(:hostname_normalized, normalized_value(value))
        end
        write_attribute(:hostname_raw, value)
      end
    end
  end

  module Normalize
    def normalized_value(raw)
      return raw if raw.nil?
      raw.strip.downcase
    end
  end

  module Naming
    def display_name
      return hostname_raw
    end
  end

  self.table_name = "cybox_hostnames"

  include Auditable
  include Hostname::RawAttribute::Writers
  include Hostname::Normalize
  include Hostname::Naming
  include Guidable
  include Cyboxable
  include Ingestible
  include AcsDefault
  include Serialized
  include ClassifiedObject
  include Transferable

  CLASSIFICATION_CONTAINED_BY = [:course_of_actions, :ind_course_of_actions, :socket_addresses,
                                 :socket_address_hostnames, :indicators, :parameter_observables]
  
  has_many :observables, -> { where remote_object_type: 'Hostname' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, dependent: :destroy
  has_many :indicators, through: :observables
  has_many :ind_course_of_actions, through: :indicators, class_name: 'CourseOfAction', source: :course_of_actions

  has_many :parameter_observables, -> { where remote_object_type: 'Hostname' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
  has_many :course_of_actions, through: :parameter_observables

  has_many :socket_address_hostnames, primary_key: :cybox_object_id, foreign_key: :hostname_id, dependent: :destroy
  has_many :socket_addresses, through: :socket_address_hostnames
  
  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  alias_attribute :hostname, :hostname_normalized
  alias_attribute :hostname_c, :hostname_normalized_c
  alias_attribute :hostname_input, :hostname_raw

  validates_presence_of :hostname
  validates_presence_of :hostname_condition
  validates_presence_of :naming_system
  after_commit :set_observable_value_on_indicator

  def stix_packages
    packages = []

    packages |= self.course_of_actions.collect(&:stix_packages).flatten if self.course_of_actions.present?
    packages |= self.indicators.collect(&:stix_packages).flatten if self.indicators.present?
    packages |= self.socket_addresses.collect(&:stix_packages).flatten if self.socket_addresses.present?

    packages
  end
  
  def self.ingest(uploader, obj, parent = nil)
    x = Hostname.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "Hostname of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x = obj.cybox_object_id.nil? ? nil : Hostname.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
      if x.present? 
        x.destroy
        x = nil
      end
    end

    if x.present?
      # Destroy all existing STIX markings to be re-ingested.
      x.stix_markings.destroy_all
    end

    x ||= Hostname.new
    HumanReview.adjust(obj, uploader)
    x.hostname_condition = obj.hostname_condition
    x.hostname_raw = obj.hostname_raw                # CYBOX Obj ID generated
    x.naming_system = obj.naming_system
    x.is_domain_name = obj.is_domain_name
   
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end
    x.read_only = uploader.read_only
    x
  end

  def self.find_or_create_by(attributes, stix_markings = nil)
    # if it includes the raw but not the normalized lets normalize and try to find it
    if attributes.keys.include?(:hostname_raw) && !attributes.keys.include?(:hostname_normalized)
      a = attributes.slice!(:hostname_raw)
      
      if attributes[:hostname_raw].present?
        a[:hostname_normalized] = attributes[:hostname_raw].strip.downcase
      end
    end
    
    obj = Hostname.where(a).first
    
    if obj.blank?
      obj = Hostname.new(attributes)
      obj.set_cybox_object_id
      obj.set_guid
      obj.hostname_condition = "Equals"
      obj.naming_system = "DNS"
      
      if stix_markings.blank?
        stix_markings = Hostname.create_default_policy(obj)
      else
        stix_markings.remote_object_id = obj.guid
        stix_markings.remote_object_type = "Hostname"
        stix_markings.remote_object_field = nil
        stix_markings.save!
      end
      
      obj.stix_markings << stix_markings
      
      begin
        obj.save!
      rescue Exception => e
        ExceptionLogger.debug("[Hostname][find_or_create_by] #{e.to_s}")
      end

    else
      # if stix_markings are sent in need to check whos marking is more recent and keep that one
      if stix_markings.present? && obj.stix_markings.present?
        begin
          if stix_markings.updated_at > obj.stix_markings.first.updated_at
            obj.stix_markings.first.destroy!
            stix_markings.remote_object_id = obj.guid
            stix_markings.remote_object_type = "Hostname"
            stix_markings.remote_object_field = nil
            stix_markings.save!
          else
            stix_markings.destroy!
          end
        rescue Exception => e
          ExceptionLogger.debug("[Hostname][find_or_create_by] #{e.to_s}")
        end
      end
    end

    obj
  end

  def set_cybox_hash
    value = self.hostname_normalized
    if (self.hostname_condition == 'StartsWith')
      value = '^' + value
    elsif (self.hostname_condition == 'EndsWith')
      value += '$'
    end

    write_attribute(:cybox_hash, CyboxHash.generate(value))
  end

  def repl_params
    {
      hostname_input: hostname,
      naming_system: naming_system,
      is_domain_name: is_domain_name,
      guid: guid,
      cybox_object_id: cybox_object_id
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
      if sm.remote_object_field.present?
        case sm.remote_object_field
          when 'hostname_normalized'
            sm.controlled_structure +=
                'cybox:Properties/HostnameObj:Hostname_Value/'
          when 'naming_system'
            sm.controlled_structure +=
                'cybox:Properties/HostnameObj:Naming_System/'
          else
            sm.controlled_structure = nil
            return
        end
      end
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

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :hostname_normalized
    string :hostname_normalized
    text :hostname_condition
    string :hostname_condition
    text :naming_system
    string :naming_system
    text :cybox_object_id, as: :text_exact
    string :cybox_object_id
    text :guid, as: :text_exactm

    #Configure for Sunspot, but don't build indices for searching.  Needed for sorting while searching
    time :created_at, stored: false
    time :updated_at, stored: false
    string :portion_marking, stored: false

  end
end
