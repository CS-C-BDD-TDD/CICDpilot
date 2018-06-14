class SocketAddress < ActiveRecord::Base

  self.table_name = "cybox_socket_addresses"

  # You need this naming module because the observable audit calls on the display_name attribute
  module Naming
    def display_name
      value = ''

      value << "Addresses: " + self.addresses_normalized_cache + " | " if self.addresses_normalized_cache.present?
      value << "Hostnames: " + self.hostnames_normalized_cache + " | " if self.hostnames_normalized_cache.present?
      value << "Ports: " + self.ports_normalized_cache if self.ports_normalized_cache.present?

      if value.blank?
        value = "#{self.class.to_s.tableize.singularize.titleize}, Cybox Object ID: #{cybox_object_id}" if self.cybox_object_id.present?
      end

      return value
    end
  end

  include Auditable
  include SocketAddress::Naming
  include Guidable
  include Cyboxable
  include Ingestible
  include AcsDefault
  include Serialized
  include ClassifiedObject
  include Transferable
  
  CLASSIFICATION_CONTAINER_OF = [:socket_address_addresses, :addresses, :socket_address_hostnames, 
                                 :hostnames, :socket_address_ports, :ports]
  CLASSIFICATION_CONTAINED_BY = [:parameter_observables, :course_of_actions, :indicators, :ind_course_of_actions,
                                 :network_connection_sources, :network_connection_destinations]

  has_many :parameter_observables, -> { where remote_object_type: 'SocketAddress' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
  has_many :course_of_actions, through: :parameter_observables

  has_many :observables, -> { where remote_object_type: 'SocketAddress' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, dependent: :destroy

  has_many :indicators, through: :observables
  has_many :ind_course_of_actions, through: :indicators, class_name: 'CourseOfAction', source: :course_of_actions

  has_many :socket_address_addresses, primary_key: :cybox_object_id, foreign_key: :socket_address_id, dependent: :destroy
  has_many :addresses, through: :socket_address_addresses, before_remove: :audit_obj_removal

  has_many :ipv4_addresses,-> {where(category: 'ipv4-addr')}, through: :socket_address_addresses, class_name: 'Address', source: :address
  has_many :ipv6_addresses,-> {where(category: 'ipv6-addr')}, through: :socket_address_addresses, class_name: 'Address', source: :address

  has_many :socket_address_hostnames, primary_key: :cybox_object_id, foreign_key: :socket_address_id, dependent: :destroy
  has_many :hostnames, through: :socket_address_hostnames, before_remove: :audit_obj_removal

  has_many :socket_address_ports, primary_key: :cybox_object_id, foreign_key: :socket_address_id, dependent: :destroy
  has_many :ports, through: :socket_address_ports, before_remove: :audit_obj_removal

  has_many :network_connection_sources, class_name: 'NetworkConnection', primary_key: :cybox_object_id, foreign_key: :source_socket_address_id
  has_many :network_connection_destinations, class_name: 'NetworkConnection', primary_key: :cybox_object_id, foreign_key: :dest_socket_address_id

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  after_commit :set_observable_value_on_indicator

  alias_attribute :ip_addresses, :addresses

  before_save :set_object_caches
  after_save :update_connected_network_connections

  validate :choice_for_address_hostname

  def stix_packages
    packages = []

    packages |= self.course_of_actions.collect(&:stix_packages).flatten if self.course_of_actions.present?
    packages |= self.indicators.collect(&:stix_packages).flatten if self.indicators.present?
    packages |= self.network_connection_sources.collect(&:stix_packages).flatten if self.network_connection_sources.present?
    packages |= self.network_connection_destinations.collect(&:stix_packages).flatten if self.network_connection_destinations.present?

    packages
  end

  # Trickles down the disseminated feed value to all of the associated objects
  def trickledown_feed
    begin
      associations = ["addresses", "hostnames", "ports"]
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

  def self.ingest(uploader, obj, options = {})
    x = SocketAddress.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "Socket Address of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x = obj.cybox_object_id.nil? ? nil : SocketAddress.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
      if x.present? 
        x.destroy
        x = nil
      end
    end

    if x.present?
      # Destroy all existing STIX markings to be re-ingested.
      x.stix_markings.destroy_all
    end

    x ||= SocketAddress.new
    HumanReview.adjust(obj, uploader)
    #x.apply_condition = obj.apply_condition
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end

    # non ais attributes
    x.name_condition = obj.name_condition if obj.respond_to?(:name_condition)
    x.apply_condition = obj.apply_condition if obj.respond_to?(:apply_condition)
    x.is_reference = obj.is_reference if obj.respond_to?(:is_reference)
    x.read_only = uploader.read_only
    x
  end

  def self.find_or_create_by(attributes, stix_markings = nil)
    # We want to match an address/hostname and a port.
    if attributes.keys.include?(:address_value_raw) && attributes[:address_value_raw].present?
      add = SocketAddress.joins(:addresses).where(cybox_addresses: {address_value_raw: attributes[:address_value_raw]})
      if attributes.keys.include?(:port) && attributes[:port].present?
        add = add.joins(:ports).where(cybox_ports: {port: attributes[:port]})
      elsif attributes.keys.include?(:port)
        add = add.where(ports_normalized_cache: ["", nil])
      end
      add = add.first
    elsif attributes.keys.include?(:hostname_raw) && attributes[:hostname_raw].present?
      add = SocketAddress.joins(:hostnames).where(cybox_hostnames: {hostname_raw: attributes[:hostname_raw]})
      if attributes.keys.include?(:port) && attributes[:port].present?
        add = add.joins(:ports).where(cybox_ports: {port: attributes[:port]})
      elsif attributes.keys.include?(:port)
        add = add.where(ports_normalized_cache: ["", nil])
      end
      add = add.first
    elsif attributes.keys.include?(:port)
      add = SocketAddress.joins(:ports).where(cybox_ports: {port: attributes[:port]})
      add = add.where(:addresses_normalized_cache => "") if attributes.keys.include?(:address_value_raw) && attributes[:address_value_raw].blank?
      add = add.where(:hostnames_normalized_cache => "") if attributes.keys.include?(:hostname_raw) && attributes[:hostname_raw].blank?
      add = add.first
    end
    
    if add.blank?
      add = SocketAddress.new
      add.set_cybox_object_id
      add.set_guid
      add.addresses << Address.find_or_create_by(:address_value_raw => attributes[:address_value_raw]) if attributes[:address_value_raw].present?
      add.hostnames << Hostname.find_or_create_by(:hostname_raw => attributes[:hostname_raw]) if attributes[:hostname_raw].present?
      add.ports << Port.find_or_create_by(:port => attributes[:port]) if attributes[:port].present?
      
      if stix_markings.blank?
        stix_markings = SocketAddress.create_default_policy(add)
      else
        stix_markings.remote_object_id = add.guid
        stix_markings.remote_object_type = "SocketAddress"
        stix_markings.remote_object_field = nil
        stix_markings.save!
      end
      
      add.stix_markings << stix_markings
      
      begin
        add.save!
      rescue Exception => e
        ExceptionLogger.debug("[SocketAddress][find_or_create_by] #{e.to_s}")
      end
    else
      # if stix_markings are sent in need to check whos marking is more recent and keep that one
      if stix_markings.present? && add.stix_markings.present?
        begin
          if stix_markings.updated_at > add.stix_markings.first.updated_at
            add.stix_markings.first.destroy!
            stix_markings.remote_object_id = add.guid
            stix_markings.remote_object_type = "SocketAddress"
            stix_markings.remote_object_field = nil
            stix_markings.save!
          else
            stix_markings.destroy!
          end
        rescue Exception => e
          ExceptionLogger.debug("[SocketAddress][find_or_create_by] #{e.to_s}")
        end
      end
    end

    add
  end

  def address_cybox_object_ids=(cybox_object_ids)
    self.address_ids = Address.where(cybox_object_id: cybox_object_ids).pluck(:id)
  end

  def hostname_cybox_object_ids=(cybox_object_ids)
    self.hostname_ids = Hostname.where(cybox_object_id: cybox_object_ids).pluck(:id)
  end

  def port_cybox_object_ids=(cybox_object_ids)
    self.port_ids = Port.where(cybox_object_id: cybox_object_ids).pluck(:id)
  end

  def duplication_needed?
    cybox_object_id && cybox_object_id.include?(Setting.READ_ONLY_EXT)
  end

  def set_cybox_hash
    write_attribute(:cybox_hash, CyboxHash.generate(self.guid))
  end

  def repl_params
    {
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

  def choice_for_address_hostname
    if self.addresses.present? && self.hostnames.present?
      errors.add(:Attached, "Addresses and Hostnames cannot both be present.")
      return false
    end

    return true
  end

  def set_object_caches
    if self.addresses.present?
      cache_value = self.addresses.map(&:address_value_normalized).to_sentence
      if cache_value.length > 255
        self.addresses_normalized_cache = cache_value[0..251] + "..."
      else
        self.addresses_normalized_cache = cache_value
      end
    else
      self.addresses_normalized_cache = ""
    end

    if self.hostnames.present?
      cache_value = self.hostnames.map(&:hostname_normalized).to_sentence
      if cache_value.length > 255
        self.hostnames_normalized_cache = cache_value[0..251] + "..."
      else
        self.hostnames_normalized_cache = cache_value
      end
    else
      self.hostnames_normalized_cache = ""
    end

    if self.ports.present?
      cache_value = self.ports.map(&:port).to_sentence
      if cache_value.length > 255
        self.ports_normalized_cache = cache_value[0..251] + "..."
      else
        self.ports_normalized_cache = cache_value
      end
    else
      self.ports_normalized_cache = ""
    end
  end

  def total_sightings
    cnt = 0
    cnt = indicators.collect{|ind| ind.sightings.size}.sum
    return cnt
  end

  private

  def update_connected_network_connections
    self.network_connection_sources.each do |net|
      net.update_cache_values(self)
    end

    self.network_connection_destinations.each do |net|
      net.update_cache_values(self)
    end
  end

  def set_observable_value_on_indicator
    self.indicators.each do |indicator|
      indicator.set_observable_value
    end
  end

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    time :created_at, stored: false
    time :updated_at, stored: false
    text :cybox_object_id, as: :text_exact
    text :hostnames_normalized_cache
    text :ports_normalized_cache
    string :hostnames_normalized_cache
    string :ports_normalized_cache
    string :cybox_object_id
    string :portion_marking, stored: false
    text :guid, as: :text_exactm

    text :hostnames do
      hostnames.map(&:hostname)
    end
    
    text :hostnames_naming_system do
      hostnames.map(&:naming_system)
    end

    text :addresses, as: :addresses_text_ipm do
      addresses.map(&:address)
    end

    text :port do
      ports.map(&:port)
    end
    
    text :port_layer4_protocol do
      ports.map(&:layer4_protocol)
    end

  end
end
