class NetworkConnection < ActiveRecord::Base
  module Naming
    def display_name
      value = ''
      if (self.source_socket_address).present?
        value += self.source_socket_address
      elsif (self.source_socket_hostname).present?
        value += self.source_socket_hostname
      end
      if (self.source_socket_port).present?
        value += ':' + self.source_socket_port
      end
      if (self.layer4_protocol).present?
        value += '/' + self.layer4_protocol
      end

      if (self.dest_socket_address).present?
        value += ' ' + self.dest_socket_address
      elsif (self.dest_socket_hostname).present?
        value += ' ' + self.dest_socket_hostname
      end
      if (self.dest_socket_port).present?
        value += ':' + self.dest_socket_port
      end
      if (self.layer4_protocol).present?
        value += '/' + self.layer4_protocol
      end
      value.present? ? value : self.cybox_object_id
    end
  end


  self.table_name = 'cybox_network_connections'

  include Auditable
  include NetworkConnection::Naming
  include Guidable
  include Cyboxable
  include Ingestible
  include AcsDefault
  include Serialized
  include Transferable

  has_many :observables, -> { where remote_object_type: 'NetworkConnection' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, dependent: :destroy
  has_many :indicators, through: :observables
  has_many :ind_course_of_actions, through: :indicators, class_name: 'CourseOfAction', source: :course_of_actions
  
  has_many :parameter_observables, -> { where remote_object_type: 'NetworkConnection' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
  has_many :course_of_actions, through: :parameter_observables

  belongs_to :source_socket_address_obj, class_name: 'SocketAddress', primary_key: :cybox_object_id, foreign_key: :source_socket_address_id
  belongs_to :dest_socket_address_obj, class_name: 'SocketAddress', primary_key: :cybox_object_id, foreign_key: :dest_socket_address_id

  has_many :network_connection_layer_seven_connections, primary_key: :cybox_object_id, foreign_key: :network_connection_id, dependent: :destroy
  has_many :layer_seven_connections, through: :network_connection_layer_seven_connections, before_remove: :audit_obj_removal
  has_many :dns_queries, through: :layer_seven_connections
  has_many :http_sessions, through: :layer_seven_connections

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  validate :either_address_or_hostname
  validate :valid_address
  validate :any_required_fields_present?

  after_save :set_addresses
  after_save :update_linked_indicators
  after_commit :set_observable_value_on_indicator

  accepts_nested_attributes_for :layer_seven_connections

  def stix_packages
    packages = []

    packages |= self.course_of_actions.collect(&:stix_packages).flatten if self.course_of_actions.present?
    packages |= self.indicators.collect(&:stix_packages).flatten if self.indicators.present?

    packages
  end

  # Trickles down the disseminated feed value to all of the associated objects
  def trickledown_feed
    begin
      associations = ["source_socket_address_obj", "dest_socket_address_obj", "dns_queries", "http_sessions"]
      associations.each do |a|       
        object = self.send a
        if object.present? && self.feeds.present?
          if object.class.to_s.include?("Collection")
            object.each do |x|
              x.update_column(:feeds, self.feeds)
              x.try(:trickledown_feed)
            end
          else
            object.update_column(:feeds, self.feeds) 
            object.try(:trickledown_feed)
          end
        end
      end
    rescue Exception => e
      ex_msg = "Exception during trickledown_feed on: " + self.class.name    
      ExceptionLogger.debug("#{ex_msg}" + ". #{e.to_s}")
    end
  end  
  

  def set_addresses
    ss_add_obj = {}
    sd_add_obj = {}
    source_markings = []
    dest_markings = []

    # Collect the stix markings to be used to create the the socket addresses
    if self.stix_markings.present?
      source_markings = self.stix_markings.select {|x| x.remote_object_field == "source_socket_address" || x.remote_object_field == "source_socket_hostname"}
      dest_markings = self.stix_markings.select {|x| x.remote_object_field == "dest_socket_address" || x.remote_object_field == "dest_socket_hostname"}
    end

    if(self.source_socket_address || self.source_socket_hostname)
      ss_add_obj = SocketAddress.find_or_create_by(
        {:address_value_raw => self.source_socket_address, :port => self.source_socket_port, :hostname_raw => self.source_socket_hostname}, source_markings.first
      )
    end

    if(self.dest_socket_address || self.dest_socket_hostname || self.dest_socket_port)
      sd_add_obj = SocketAddress.find_or_create_by(
        {:address_value_raw => self.dest_socket_address, :hostname_raw => self.dest_socket_hostname, :port => self.dest_socket_port}, dest_markings.first
        )
    end

    if ss_add_obj.present?
      self.update_column(:source_socket_address_id, ss_add_obj.cybox_object_id)
    end

    if sd_add_obj.present?
      self.update_column(:dest_socket_address_id, sd_add_obj.cybox_object_id)
    end

  end

  def update_cache_values(socket_address)
    return if socket_address.blank?

    if socket_address.cybox_object_id == self.source_socket_address_id
      if socket_address.addresses_normalized_cache.present?
        self.update_column(:source_socket_address , socket_address.addresses_normalized_cache)
      elsif socket_address.hostnames_normalized_cache.present?
        self.update_column(:source_socket_hostname , socket_address.hostnames_normalized_cache)
      end

      if socket_address.ports_normalized_cache.present?
        self.update_column(:source_socket_port , socket_address.ports_normalized_cache)
      end
    elsif socket_address.cybox_object_id == self.dest_socket_address_id
      if socket_address.addresses_normalized_cache.present?
        self.update_column(:dest_socket_address , socket_address.addresses_normalized_cache)
      elsif socket_address.hostnames_normalized_cache.present?
        self.update_column(:dest_socket_hostname , socket_address.hostnames_normalized_cache)
      end

      if socket_address.ports_normalized_cache.present?
        self.update_column(:dest_socket_port , socket_address.ports_normalized_cache)
      end
    end

    self.update_linked_indicators;
    self.set_observable_value_on_indicator;
      
  end

  def layer_seven_connection_guids=(guids)
    self.layer_seven_connection_ids = LayerSevenConnection.where(guid: guids).pluck(:id)
  end

  def self.ingest(uploader, obj, parent = nil)
    x = NetworkConnection.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "Network connection of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x = obj.cybox_object_id.nil? ? nil : NetworkConnection.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
    end

    if x.present?
      # Destroy all existing STIX markings to be re-ingested.
      x.layer_seven_connections.destroy_all
      x.stix_markings.destroy_all
    end

    x ||= NetworkConnection.new
    HumanReview.adjust(obj, uploader)
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end
    #x.dest_socket_address = obj.dest_socket_address
    #x.dest_socket_hostname = obj.dest_socket_hostname
    #x.dest_socket_is_spoofed = obj.dest_socket_is_spoofed
    #x.dest_socket_port = obj.dest_socket_port
    #x.source_socket_address = obj.source_socket_address
    #x.source_socket_hostname = obj.source_socket_hostname
    #x.source_socket_is_spoofed = obj.source_socket_is_spoofed
    #x.source_socket_port = obj.source_socket_port
    x.layer3_protocol = obj.layer3_protocol
    x.layer4_protocol = obj.layer4_protocol
    x.layer7_protocol = obj.layer7_protocol
    x.read_only = uploader.read_only

    x
  end

  def set_cybox_hash
    value = ''
    if self.source_socket_address
      value += self.source_socket_address
    elsif self.source_socket_hostname
      value += self.source_socket_hostname
    end
    if self.source_socket_port
      value += self.source_socket_port.to_s
    end
    if self.source_socket_address && self.source_socket_is_spoofed
      value += 'spoofed'
    end

    if self.dest_socket_address
      value += ' ' + self.dest_socket_address
    elsif self.dest_socket_hostname
      value += ' ' + self.dest_socket_hostname
    end
    if self.dest_socket_port
      value += self.dest_socket_port.to_s
    end
    if self.dest_socket_address && self.dest_socket_is_spoofed
      value += 'spoofed'
    end
    if self.layer3_protocol
      value += self.layer3_protocol
    end
    if self.layer4_protocol
      value += self.layer4_protocol
    end
    if self.layer7_protocol
      value += self.layer7_protocol
    end

    value = self.cybox_object_id if value.blank?

    write_attribute(:cybox_hash, CyboxHash.generate(value))
  end

  def repl_params
    {
        :dest_socket_address      => dest_socket_address,
        :dest_socket_hostname     => dest_socket_hostname,
        :dest_socket_is_spoofed   => dest_socket_is_spoofed,
        :dest_socket_port         => dest_socket_port,
        :source_socket_address    => source_socket_address,
        :source_socket_hostname   => source_socket_hostname,
        :source_socket_is_spoofed => source_socket_is_spoofed,
        :source_socket_port       => source_socket_port,
        :layer3_protocol          => layer3_protocol,
        :layer4_protocol          => layer4_protocol,
        :layer7_protocol          => layer7_protocol,
        :guid                     => guid,
        :cybox_object_id          => cybox_object_id
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
          when 'layer3_protocol'
            sm.controlled_structure +=
                'cybox:Properties/NetworkConnectionObj:Layer3_Protocol/'
          when 'layer4_protocol'
            sm.controlled_structure +=
                'cybox:Properties/NetworkConnectionObj:Layer4_Protocol/'
          when 'layer7_protocol'
            sm.controlled_structure +=
                'cybox:Properties/NetworkConnectionObj:Layer7_Protocol/'
          else
            sm.controlled_structure = nil
            return
        end
      end
      sm.controlled_structure += 'descendant-or-self::node()'
      sm.controlled_structure += "| #{sm.controlled_structure}/@*"
    end
  end

  # Move out of private since we need to call it for updating cache columns.
  def set_observable_value_on_indicator
    self.indicators.each do |indicator|
      indicator.set_observable_value
    end
  end

  def update_linked_indicators
    unless self.changes.empty?
      self.indicators.each do |i|
        audit = Audit.basic
        audit.message = "Network connection observable updated"
        audit.details = self.changes.except("updated_at")
        audit.item = i
        audit.audit_type = :observable_update
        i.audits << audit
        i.updated_at = Time.now
        i.save
      end
    end
  end

  def total_sightings
    cnt = 0
    cnt = indicators.collect{|ind| ind.sightings.size}.sum
    return cnt
  end

  private


  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :dest_socket_address, as: :text_ipm
    string :dest_socket_address
    text :dest_socket_hostname
    string :dest_socket_hostname
    text :dest_socket_port
    string :dest_socket_port
    text :source_socket_address, as: :text_ipm
    string :source_socket_address
    text :source_socket_hostname
    string :source_socket_hostname
    text :source_socket_port
    string :source_socket_port
    text :layer3_protocol
    string :layer3_protocol
    text :layer4_protocol
    string :layer4_protocol
    text :layer7_protocol
    string :layer7_protocol
    time :created_at, stored:false
    time :updated_at, stored:false
    text :cybox_object_id, as: :text_exact
    string :cybox_object_id
    string :portion_marking, stored: false
    text :guid, as: :text_exactm

    text :http_session_user_agent do
      http_sessions.map(&:user_agent)
    end

    text :http_session_domain_name do
      http_sessions.map(&:domain_name)
    end

    text :http_session_referer, as: :http_session_referer_text_uaxm do
      http_sessions.map(&:referer)
    end

    text :dns_query_question do
      dns_queries.map(&:question_normalized_cache)
    end

    text :dns_query_answer_resource_record do
      dns_queries.map(&:answer_normalized_cache)
    end

    text :dns_query_authority_resource_record do
      dns_queries.map(&:authority_normalized_cache)
    end

    text :dns_query_additional_record do 
      dns_queries.map(&:additional_normalized_cache)
    end

  end

  def self.valid_ipv4_value?(raw)
    begin
      IPAddress::IPv4.new(raw.strip)
      true
    rescue ArgumentError
      false
    end
  end

  def valid_ipv6_value?(raw)
    begin
      IPAddress::IPv6.new(raw.strip)
      true
    rescue ArgumentError
      false
    end
  end

  def valid_address
    return unless dest_socket_address.present?
    unless Address.valid_ipv4_value?(dest_socket_address) || Address.valid_ipv6_value?(dest_socket_address)
      errors.add(:dest_socket_address, "`#{dest_socket_address}` is not valid.  Must be a valid IP address")
    end
    return unless source_socket_address.present?
    unless Address.valid_ipv4_value?(source_socket_address) || Address.valid_ipv6_value?(source_socket_address)
      errors.add(:source_socket_address, "`#{source_socket_address}` is not valid.  Must be a valid IP address")
    end
  end

  def either_address_or_hostname
    errors.add(:dest_socket_address, 'Both a hostname and an IP address ' +
        'are present for the destination socket. Only of these fields is ' +
        'permitted.') if dest_socket_hostname.present? &&
        dest_socket_address.present?
    errors.add(:dest_socket_address, 'A hostname was specified for the ' +
        'destination socket but was incorrectly flagged as a spoofed ' +
        'IP address.') if dest_socket_hostname.present? &&
        dest_socket_is_spoofed
    errors.add(:source_socket_address, 'Both a hostname and an IP address ' +
        'are present for the source socket. Only of these fields is ' +
        'permitted.') if source_socket_hostname.present? &&
        source_socket_address.present?
    errors.add(:source_socket_address, 'A hostname was specified for the ' +
        'source socket but was incorrectly flagged as a spoofed ' +
        'IP address.') if source_socket_hostname.present? &&
        source_socket_is_spoofed
  end

  def any_required_fields_present?
    field_list = ['source_socket_address','source_socket_hostname']
    if field_list.all?{|attr| self[attr].blank?}
      errors.add :source_socket_address, 'You must fill in Source Address or Source Hostname'
    end
  end
end
