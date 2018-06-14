class Port < ActiveRecord::Base
  require 'csv'
  
  module Naming
    def display_name
      value = ''
      if (self.port)
        value += self.port
      end
      if (self.layer4_protocol)
        value += '/' + self.layer4_protocol
      end
      value.present? ? value : self.cybox_object_id
    end
  end

  self.table_name = "cybox_ports"

  include Auditable
  include Port::Naming
  include Guidable
  include Cyboxable
  include Ingestible
  include AcsDefault
  include Serialized
  include ClassifiedObject
  include Transferable

  CLASSIFICATION_CONTAINED_BY = [:course_of_actions, :ind_course_of_actions, :socket_addresses,
                                 :socket_address_ports, :indicators, :parameter_observables]
  
  has_many :observables, -> { where remote_object_type: 'Port' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, dependent: :destroy
  has_many :indicators, through: :observables
  has_many :ind_course_of_actions, through: :indicators, class_name: 'CourseOfAction', source: :course_of_actions

  has_many :parameter_observables, -> { where remote_object_type: 'Port' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
  has_many :course_of_actions, through: :parameter_observables

  has_many :socket_address_ports, primary_key: :cybox_object_id, foreign_key: :port_id, dependent: :destroy
  has_many :socket_addresses, through: :socket_address_ports

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  validates_presence_of :port
  validates_presence_of :layer4_protocol
  after_commit :set_observable_value_on_indicator
  validates :port, numericality: { greater_than: 0, less_than: 65536 }

  def stix_packages
    packages = []

    packages |= self.course_of_actions.collect(&:stix_packages).flatten if self.course_of_actions.present?
    packages |= self.indicators.collect(&:stix_packages).flatten if self.indicators.present?
    packages |= self.socket_addresses.collect(&:stix_packages).flatten if self.socket_addresses.present?

    packages
  end

  def self.ingest(uploader, obj, parent = nil)
    x = Port.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "Port of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x = obj.cybox_object_id.nil? ? nil : Port.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
      if x.present? 
        x.destroy
        x = nil
      end
    end

    if x.present?
      # Destroy all existing STIX markings to be re-ingested.
      x.stix_markings.destroy_all
    end

    x ||= Port.new
    HumanReview.adjust(obj, uploader)
    x.port = obj.port
    x.layer4_protocol = obj.layer4_protocol                # CYBOX Obj ID generated
   
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end
    x.read_only = uploader.read_only
    x
  end

  def self.find_or_create_by(attributes, stix_markings = nil)
    obj = Port.where(attributes).first
    
    if obj.blank?
      obj = Port.new(attributes)
      obj.set_cybox_object_id
      obj.set_guid
      obj.layer4_protocol = "TCP"
      
      if stix_markings.blank?
        stix_markings = Port.create_default_policy(obj)
      else
        stix_markings.remote_object_id = obj.guid
        stix_markings.remote_object_type = "Port"
        stix_markings.remote_object_field = nil
        stix_markings.save!
      end
      
      obj.stix_markings << stix_markings
      
      begin
        obj.save!
      rescue Exception => e
        ExceptionLogger.debug("[Port][find_or_create_by] #{e.to_s}")
      end

    else
      # if stix_markings are sent in need to check whos marking is more recent and keep that one
      if stix_markings.present? && obj.stix_markings.present?
        begin
          if stix_markings.updated_at > obj.stix_markings.first.updated_at
            obj.stix_markings.first.destroy!
            stix_markings.remote_object_id = obj.guid
            stix_markings.remote_object_type = "Port"
            stix_markings.remote_object_field = nil
            stix_markings.save!
          else
            stix_markings.destroy!
          end
        rescue Exception => e
          ExceptionLogger.debug("[Port][find_or_create_by] #{e.to_s}")
        end
      end
    end

    obj
  end

  def set_cybox_hash
    value = ''
    if self.port
      value += self.port.to_s
    end
    
    if self.layer4_protocol
      value += self.layer4_protocol
    end
    
    value = self.cybox_object_id if value.blank?

    write_attribute(:cybox_hash, CyboxHash.generate(value))
  end

  def repl_params
    {
      port: port,
      layer4_protocol: layer4_protocol,
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
          when 'port'
            sm.controlled_structure +=
                'cybox:Properties/PortObj:Port_Value/'
          when 'layer4_protocol'
            sm.controlled_structure +=
                'cybox:Properties/PortObj:Layer4_Protocol/'
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
    text :port
    string :port
    text :layer4_protocol
    string :layer4_protocol
    text :cybox_object_id, as: :text_exact
    string :cybox_object_id
    text :guid, as: :text_exactm


    #Configure for Sunspot, but don't build indices for searching.  Needed for sorting while searching
    time :created_at, stored: false
    time :updated_at, stored: false
    string :portion_marking, stored: false

  end
end
