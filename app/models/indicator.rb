class Indicator < ActiveRecord::Base
  include AcsDefault
  include Transferable

  self.table_name = "stix_indicators"

  has_many :indicators_packages,
            primary_key: :stix_id,
            foreign_key: :stix_indicator_id,
            dependent: :destroy

  has_many :stix_packages,
            through: :indicators_packages

  has_many :sightings, primary_key: :stix_id, foreign_key: :stix_indicator_id, dependent: :destroy
  has_many :attachments, class_name: 'OriginalInput', primary_key: :stix_id, as: :remote_object, foreign_key: :remote_object_id
  has_many :uploaded_files, through: :attachments
  has_many :observables, ->{reorder(created_at: :asc)}, primary_key: :stix_id, foreign_key: :stix_indicator_id, dependent: :destroy
  has_many :dns_records, through: :observables
  has_many :domains, through: :observables
  has_many :hostnames, through: :observables
  has_many :email_messages, through: :observables
  has_many :files, through: :observables
  has_many :http_sessions, through: :observables
  has_many :addresses, through: :observables
  
  has_many :links, through: :observables
  has_many :dns_queries, through: :observables
  has_many :ipv4_addresses,-> {where(category: 'ipv4-addr')}, through: :observables, class_name: 'Address', source: :address
  has_many :ipv6_addresses,-> {where(category: 'ipv6-addr')}, through: :observables, class_name: 'Address', source: :address
  has_many :weather_map_addresses,-> {where.not(combined_score: nil)},class_name: "Address", through: :observables, source: :address
  has_many :weather_map_domains,-> {where.not(combined_score: nil)},class_name: "Domain", through: :observables, source: :domain
  has_many :mutexes, through: :observables
  has_many :network_connections, through: :observables
  has_many :ports, through: :observables
  has_many :registries, through: :observables
  has_many :socket_addresses, through: :observables
  has_many :uris, through: :observables
  has_many :kill_chain_refs,
           primary_key: :stix_id,
           as: :remote_object,
           dependent: :destroy
  has_many :kill_chain_phases,
           through: :kill_chain_refs,
           primary_key: :stix_kill_chain_phase_id,
           foreign_key: :stix_kill_chain_phase_id
  has_many :kill_chains,
           through: :kill_chain_refs,
           primary_key: :stix_kill_chain_id,
           foreign_key: :stix_kill_chain_id

  has_many :tag_assignments,
           primary_key: :guid,
           foreign_key: :remote_object_guid,
           as: :remote_object,
           dependent: :destroy

  has_many :indicators_threat_actors, primary_key: :stix_id, foreign_key: :stix_indicator_id

  has_many :threat_actors,
           through: :indicators_threat_actors,
           before_remove: :audit_threat_actor_removal
           
  has_many :indicators_course_of_actions, primary_key: :stix_id, foreign_key: :stix_indicator_id, dependent: :destroy

  has_many :course_of_actions,
           through: :indicators_course_of_actions,
           before_remove: :audit_course_of_action_removal

  has_many :indicator_ttps, primary_key: :stix_id, foreign_key: :stix_indicator_id, dependent: :destroy

  has_many :ttps, through: :indicator_ttps, before_remove: :audit_ttp_removal

  has_many :system_tags,
           through: :tag_assignments,
           primary_key: :guid,
           foreign_key: :tag_guid,
           dependent: :destroy,
           before_remove: :audit_tag_removal

  has_many :user_tags,
           through: :tag_assignments,
           primary_key: :guid,
           foreign_key: :tag_guid,
           dependent: :destroy,
           before_remove: :audit_tag_removal

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  has_many :confidences, -> {reorder(is_official: :desc).order(stix_timestamp: :desc)},primary_key: :guid, as: :remote_object,dependent: :destroy
  has_one :official_confidence,-> {where(is_official: true).order(stix_timestamp: :desc).limit(1)},class_name: "Confidence", primary_key: :guid, as: :remote_object,dependent: :destroy
  has_many :exported_indicators,primary_key: :guid, dependent: :destroy
  belongs_to :created_by_user, class_name: 'User', primary_key: :guid, foreign_key: :created_by_user_guid
  belongs_to :updated_by_user, class_name: 'User', primary_key: :guid, foreign_key: :updated_by_user_guid
  belongs_to :created_by_organization, class_name: 'Organization', primary_key: :guid, foreign_key: :created_by_organization_guid
  belongs_to :updated_by_organization, class_name: 'Organization', primary_key: :guid, foreign_key: :updated_by_organization_guid
  has_many :fo_threat_actors, -> {where("title like 'FO%'")}, through: :indicators_threat_actors, source: :threat_actor, class_name: "ThreatActor"

  has_many :related_to_objects,->{where(remote_src_object_type: 'Indicator')}, primary_key: :guid, foreign_key: :remote_src_object_guid, class_name: 'Relationship', dependent: :destroy
  has_many :related_by_objects,->{where(remote_dest_object_type: 'Indicator')}, primary_key: :guid, foreign_key: :remote_dest_object_guid, class_name: 'Relationship', dependent: :destroy
  has_many :related_to_indicators, through: :related_to_objects,source_type: 'Indicator',source: :remote_dest_object
  has_many :related_by_indicators, through: :related_by_objects,source_type: 'Indicator',source: :remote_src_object
  has_many :stix_markings, primary_key: :guid, as: :remote_object, dependent: :destroy
  has_many :isa_marking_structures, primary_key: :stix_id, through: :stix_markings, dependent: :destroy
  has_many :isa_assertion_structures, primary_key: :stix_id, through: :stix_markings, dependent: :destroy
  belongs_to :acs_set, primary_key: :guid
  belongs_to :indicator_zip

  validates_presence_of :title, :indicator_type
  validate :user_presence
  validates_length_of :downgrade_request_id, :maximum => 50
  validates_length_of :reference, maximum: 255
  validate :indicator_scoring_types
  before_save :set_controlled_structures

  accepts_nested_attributes_for :confidences, reject_if: proc {|attributes| attributes['value'].blank?}
  accepts_nested_attributes_for :stix_markings, allow_destroy: true, reject_if: :update_markings
  accepts_nested_attributes_for :observables, reject_if: :observable_create_update

  alias_attribute :color,:legacy_color
  
  #Normalized symbol as key, array of possible string values as value.  UI will display first value in array
  INDICATOR_TYPES = {
      anonymization: ['Anonymization'],
      benign: ['Benign'],
      c2: ['C2'],
      compromised: ['Compromised','Compromised PKI Certificate'],
      domain_watchlist: ['Domain Watchlist'],
      exfiltration: ['Exfiltration'],
      file_hash_watchlist: ['File Hash Watchlist'],
      host_characteristics: ['Host Characteristics'],
      ip_watchlist: ['IP Watchlist'],
      malicious_email: ['Malicious E-mail'],
      malware_artifacts: ['Malware Artifacts'],
      url_watchlist: ['URL Watchlist'],
      needs_definition: ['Needs Definition']
  }

  # Array of indicator types that are from the CISCP "extension" vocab
  CISCP_INDICATOR_TYPES = [:benign, :compromised]

  # The two currently used variant of IndicatorTypeVocab until the CISCP
  # vocab is converted into a proper extension to incorporate the Stix defaults.
  INDICATOR_TYPE_VOCABS = {
      stix_vocabs_1_0: ' xsi:type="stixVocabs:IndicatorTypeVocab-1.0"',
      # ciscp_0_0: ' xsi:type="CISCP:IndicatorTypeVocab-0.0"',
      ciscp_0_0: ''
  }

  # Values needed for indicator scoring
  TIMELINES = [
    {score: 10, name: "< 30 Days : 10"}, 
    {score: 8, name: "3-6 Months : 8"},
    {score: 6, name: "6-12 Months : 6"},
    {score: 3, name: "> 12 Months : 3"}
  ]

  SOURCE_OF_REPORT = [
    {score: 10, name: "GFI1/OGA : 10"},
    {score: 8, name: "DoD : 8"},
    {score: 6, name: "USGA : 6"},
    {score: 6, name: "ISAC : 6"},
    {score: 3, name: "Foreign/Open Source : 3"}
  ]

  TARGET_OF_ATTACK = [
    {score: 10, name: "USGA : 10"},
    {score: 8, name: "CDC : 8"},
    {score: 8, name: "ICS : 8"},
    {score: 8, name: "Section 7 : 8"},
    {score: 6, name: "ISAC (Financial, Aviation, State) : 6"},
    {score: 6, name: "CAE/Think Tank : 6"},
    {score: 5, name: "DoD : 5"},
    {score: 3, name: "Unknown : 3"}
  ]

  TARGET_SCOPE = [
    {score: 10, name: "Highly Targeted/Subset of Group/Select People in Organization : 10"},
    {score: 8, name: "General/Multiple Entities : 8"},
    {score: 6, name: "Targeted/Single Entity : 6"},
    {score: 3, name: "Unknown : 3"}
  ]

  ACTOR_ATTRIBUTION = [
    {score: 10, name: "Known : 10"},
    {score: 8, name: "Probable/Likely/Possible : 8"},
    {score: 8, name: "Suspected : 8"},
    {score: 6, name: "Unattributed : 6"},
    {score: 3, name: "Unknown : 3"}
  ]

  ACTOR_TYPE = [
    {score: 10, name: "Nation state (NS) : 10"},
    {score: 8, name: "Third Party Associated with NS : 8"},
    {score: 6, name: "Non-Nation State : 6"},
    {score: 6, name: "Unattributed Foreign CNE : 6"},
    {score: 3, name: "Cybercriminal : 3"}
  ]

  MODUS_OPERANDI = [
    {score: 10, name: "Malware Propagation (RAT/Destruction/C2/Exfil/Ransomware) : 10"},
    {score: 8, name: "Any High Visibility Trending Threat : 8"},
    {score: 6, name: "Credential Harvesting : 6"},
    {score: 3, name: "Enumeration : 3"},
    {score: 3, name: "Unknown : 3"}
  ]
  
# Trickles down the disseminated feed value to all of the associated objects
def trickledown_feed
  begin
    associations = ["ttps", "course_of_actions", "observables"]
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

  def indicator_type=(indicator_type)
    if indicator_type.nil? || indicator_type.to_sym == :needs_definition
      write_attribute(:indicator_type, :needs_definition)
    else
      indicator_types = INDICATOR_TYPES
      if indicator_types.keys.include?(indicator_type.to_sym)
        write_attribute(:indicator_type, indicator_type)
      else
        types = {}
        indicator_types.invert.each_pair do |key,value|
          key.each {|k| types.merge!(Hash[k.downcase.gsub(/ |-/,''),value])}
        end
        ind_type = indicator_type.downcase.gsub(/ |-|_/,'')
        if types.keys.include?(ind_type)
          write_attribute(:indicator_type,types[ind_type])
        end
      end
    end
  end

  # Get the proper xsi:type value for the vocab containing the current
  # indicator type
  def indicator_type_vocab
    (indicator_type.present? &&
        CISCP_INDICATOR_TYPES.include?(indicator_type.to_sym)) ?
        INDICATOR_TYPE_VOCABS[:ciscp_0_0] :
        INDICATOR_TYPE_VOCABS[:stix_vocabs_1_0]
  end

  # Get the first value in the array to display for the indicator type in the
  # UI when displaying the XML or nil if the indicator type is nil or
  # needs_definition to suppress adding the indicator type element to the XML
  # output.
  def indicator_type_first
    (indicator_type.nil? || indicator_type.to_sym == :needs_definition) ?
        nil : INDICATOR_TYPES[indicator_type.to_sym].first
  end

  def user_tag_guids=(guids)
    self.user_tag_ids = UserTag.where(guid: guids).pluck(:id)
  end

  def system_tag_guids=(guids)
    self.system_tag_ids = SystemTag.where(guid: guids).pluck(:id)
  end

  def course_of_action_stix_ids=(stix_ids)
    self.course_of_action_ids = CourseOfAction.where(stix_id: stix_ids).pluck(:id)
  end

  def ttp_stix_ids=(stix_ids)
    self.ttp_ids = Ttp.where(stix_id: stix_ids).pluck(:id)
  end
  
  def total_sightings
    count = 0
    
    if observables.present?
      observables.each {|obsv|
        count += obsv.total_sightings
      }
    elsif sightings.present?
      count = sightings.size
    end
    
    return count
  end

  # This exists because User's cannot see other user's user tags.  We restrict this visibility at the
  # API.  When updating tag IDs, the tags that a user an edit must be logically separated from the
  # tags that a user cannot edit.  Then these tags must be merged.

  def update_user_tag_ids(current_user,tag_ids)
    current_user_tag_ids = user_tags.where(user_guid: current_user.guid).map(&:id)
    other_user_tag_ids = user_tags.where('tags.user_guid <> ?',current_user.guid).map(&:id)

    # We can get away with just two cases here, but I prefer
    # to be embarrasingly explicit.
    if tag_ids.blank? && current_user_tag_ids.blank?
      tag_ids = []
    elsif tag_ids.present? && current_user_tag_ids.present?
      tag_ids = tag_ids
    elsif tag_ids.present? && current_user_tag_ids.blank?
      tag_ids = tag_ids
    elsif tag_ids.blank? && current_user_tag_ids.present?
      tag_ids = []
    end
    (self.user_tag_ids = other_user_tag_ids | tag_ids)
  end

  # Same as the other one but we use guids because we need to concat the existing

  def update_user_tag_guids(current_user, tag_ids)
    current_user_tag_ids = user_tags.where(user_guid: current_user.guid).map(&:guid)
    other_user_tag_ids = user_tags.where('tags.user_guid <> ?',current_user.guid).map(&:guid)

    # We can get away with just two cases here, but I prefer
    # to be embarrasingly explicit.
    if tag_ids.blank? && current_user_tag_ids.blank?
      tag_ids = []
    elsif tag_ids.present? && current_user_tag_ids.present?
      tag_ids = tag_ids
    elsif tag_ids.present? && current_user_tag_ids.blank?
      tag_ids = tag_ids
    elsif tag_ids.blank? && current_user_tag_ids.present?
      tag_ids = []
    end
    (self.user_tag_guids = self.user_tag_ids.concat(other_user_tag_ids | tag_ids))
  end

  def title_exact
    self.title
  end

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :title, as: :text_dash_fix
    string :title
    text :title_exact, as: :text_space_in_paren_fix
    text :stix_id, as: :text_exact
    string :stix_id
    time :updated_at, stored: false
    string :indicator_type
    text :alternative_id, as: :text_exactm #don't understand why this has to be multivalued but it does
    text :description
    text :reference
    string :portion_marking, stored: false
    string :observable_type
    text :observable_value, boost: 100
    string :observable_value
    text :threat_actor_id
    string :threat_actor_id
    text :threat_actor_title
    string :threat_actor_title
    boolean :is_ais
    text :guid, as: :text_exactm

    text :observables, as: :observables_text_exactm do
      observables.map(&:cybox_object_id)
    end

    text :observables_remote, as: :observables_remote_text_exactm do
      observables.map(&:remote_object_id)
    end

    string :system_tag_id,multiple: true do
      system_tag_ids
    end

    text :system_tags do
      system_tags.map &:name
    end
    
    text :domains, as: :domains_text_domainm do
      domains.map(&:name)
    end
    
    text :hostnames do
      hostnames.map(&:hostname)
    end
    
    text :hostnames_naming_system do
      hostnames.map(&:naming_system)
    end

    text :addresses, as: :addresses_text_ipm do
      addresses.map(&:address)
    end

    long :ip_start, multiple: true do
      ipv4_addresses.map(&:ip_value_calculated_start)
    end

    long :ip_end, multiple: true do
      ipv4_addresses.map(&:ip_value_calculated_end)
    end

    text :dns_records_domain, as: :dns_records_address_text_domainm do
      dns_records.map(&:domain)
    end

    text :dns_records_address, as: :dns_records_address_text_ipm do
      dns_records.map(&:address)
    end

    text :email_messages_from, as: :email_messages_from_text_uaxm do
      email_messages.map(&:from)
    end

    text :email_messages_reply_to, as: :email_messages_reply_to_text_uaxm do
      email_messages.map(&:reply_to)
    end

    text :email_messages_sender, as: :email_messages_sender_text_uaxm do
      email_messages.map(&:sender)
    end

    text :email_messages_subject do
      email_messages.map(&:subject)
    end

    text :uris, as: :uris_text_uaxm do
      uris.map(&:uri)
    end

    text :links, as: :uris_text_uaxm do
      links.map{|link| link.uri.uri_normalized if link.uri}
    end

    text :file do
      files.map(&:file_name)
    end

    text :mutex do
      mutexes.map(&:name)
    end
    
    text :port do
      ports.map(&:port)
    end
    
    text :port_layer4_protocol do
      ports.map(&:layer4_protocol)
    end

    text :http_session_user_agent do
      http_sessions.map(&:user_agent)
    end

    text :http_session_domain_name do
      http_sessions.map(&:domain_name)
    end

    text :http_session_referer, as: :http_session_referer_text_uaxm do
      http_sessions.map(&:referer)
    end

    text :registry_key, as: :registry_key_text_regkeym do
      registries.map(&:key)
    end

    text :registry_hive do
      registries.map(&:hive)
    end

    text :network_connection_dest_socket_address, as: :network_connection_dest_socket_address_text_ipm do
      network_connections.map(&:dest_socket_address)
    end

    text :network_connection_dest_socket_hostname do
      network_connections.map(&:dest_socket_hostname)
    end

    text :network_connection_dest_socket_port do
      network_connections.map(&:dest_socket_port)
    end

    text :network_connection_source_socket_address, as: :network_connection_source_socket_address_text_ipm do
      network_connections.map(&:source_socket_address)
    end

    text :network_connection_source_socket_hostname do
      network_connections.map(&:source_socket_hostname)
    end

    text :network_connection_source_socket_port do
      network_connections.map(&:source_socket_port)
    end

    text :network_connection_layer3_protocol do
      network_connections.map(&:layer3_protocol)
    end

    text :network_connection_layer4_protocol do
      network_connections.map(&:layer4_protocol)
    end

    text :network_connection_layer7_protocol do
      network_connections.map(&:layer7_protocol)
    end

    text :hashes do
      files.map {|file| file.file_hashes.map(&:simple_hash_value_normalized) }
    end

    text :dns_query_question do
      dns_queries.map(&:question_normalized_cache)
    end

    text :dns_query_domains, as: :dns_query_address_text_domainm do
      dns_queries.map {|dns_query| dns_query.resource_records.map {|rr| rr.dns_records.map(&:domain)}}.flatten
    end

    text :dns_query_addresses, as: :dns_query_address_text_ipm do
      dns_queries.map {|dns_query| dns_query.resource_records.map {|rr| rr.dns_records.map(&:address)}}.flatten
    end
  end

  # Include Auditable MUST go after has_many audits & has_many audit_indicators
  include Auditable
  include Guidable
  include Stixable
  include Notable
  include Ingestible
  include Serialized
  include ClassifiedObject

  CLASSIFICATION_CONTAINER_OF = Observable::CYBOX_OBJECTS + [:ttps, :course_of_actions]
  CLASSIFICATION_CONTAINED_BY = [:stix_packages, :threat_actors]

  
  def self.ingest(uploader, obj, parent = nil)
    
    x = Indicator.find_by_stix_id(obj.stix_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "Indicator of #{obj.stix_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      if !obj.stix_id.nil?
        x = Indicator.find_by_stix_id(obj.stix_id + Setting.READ_ONLY_EXT)
      end
    end

    if x.present?
      x.observables.destroy_all
      x.indicators_course_of_actions.destroy_all
      x.indicator_ttps.destroy_all
      x.stix_markings.destroy_all
      x.confidences.destroy_all
      x.sightings.destroy_all
      x.acs_set_id = nil
    end

    if x.present? && (uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite))
      x.destroy
      x = nil
    end

    x ||= Indicator.new
    HumanReview.adjust(obj, uploader)
    x.description = obj.description
    x.indicator_type = obj.indicator_type
    x.indicator_type_vocab_name = obj.indicator_type_vocab_name
    x.indicator_type_vocab_ref = obj.indicator_type_vocab_ref
    x.is_composite = obj.is_composite.nil? ? false : obj.is_composite
    x.is_negated = obj.is_negated.nil? ? false : obj.is_negated
    x.is_reference = obj.is_reference.nil? ? false : obj.is_reference
    x.resp_entity_stix_ident_id = obj.responsible_entity_stix_identity_id
    # x.short_description = obj.short_description
    x.title = obj.title.nil? ? obj.stix_id : obj.title
    
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
    x.stix_timestamp = obj.stix_timestamp
    x.alternative_id = obj.alternative_id
    x.start_time = obj.start_time
    x.end_time = obj.end_time
    x.start_time_precision = obj.start_time_precision
    x.end_time_precision = obj.end_time_precision

    unless parent.nil?
      x.created_by_user_guid = parent.guid
      x.created_by_organization_guid = parent.organization_guid
      x.updated_by_user_guid = parent.guid
      x.updated_by_organization_guid = parent.organization_guid
    end

    if obj.confidences.present? && User.has_permission(User.current_user,'set_confidence_level')
      obj.confidences.collect do |confidence|
        c = Confidence.new(
            value: confidence.value,
            description: confidence.description,
            source: confidence.source,
            stix_timestamp: confidence.stix_timestamp,
            from_file: true
        )
        if c.valid?
          x.confidences << c
        else
          IngestUtilities.add_warning(uploader, c.errors.full_messages, true)
        end
      end

    end
    x.read_only = uploader.read_only

    x
  rescue
    IngestUtilities.add_warning(uploader, "Failed to build Indicator (#{obj.stix_id})")
  end

  def set_controlled_structures
    if self.stix_markings.present?
      self.stix_markings.each { |sm| set_controlled_structure(sm) }
    end
  end

  def set_controlled_structure(sm)
    if sm.present?
      sm.controlled_structure =
          "//stix:Indicator[@id='#{self.stix_id}']/"
      if sm.remote_object_field.present?
        case sm.remote_object_field
          when 'title'
            sm.controlled_structure +=
                'indicator:Title/'
          when 'description'
            sm.controlled_structure +=
                'indicator:Description/'
          when 'indicator_type'
            sm.controlled_structure +=
                'indicator:Type/'
          when 'alternative_id'
            sm.controlled_structure +=
                'indicator:Alternative_ID/'
          else
            sm.controlled_structure = nil
            return
        end
      end
      sm.controlled_structure += 'descendant-or-self::node()'
      sm.controlled_structure += "| #{sm.controlled_structure}/@*"
    end
  end

  def set_portion_marking
    return unless self.respond_to?(:portion_marking)
    return if @is_upload

    markings = self.stix_markings.select {|s| s.remote_object_field.blank? }.collect(&:isa_assertion_structure).compact.first

    object_classification = markings unless markings.nil? || markings.destroyed?
    object_classification ||= self.acs_set.stix_markings.select {|s| s.remote_object_field.blank? }.collect(&:isa_assertion_structure).compact.first if self.respond_to?(:acs_set) && self.acs_set.present?

    nw = nil
    old = self.portion_marking

    if object_classification.present?
      object_classification = object_classification.cs_classification
      nw = object_classification
      self.portion_marking = object_classification
      self.update_columns({portion_marking: object_classification})
      self.reload
    end

    return unless self.exported_indicators.present? && nw.present? && old.present?

    self.exported_indicators.each do |exp|
      audit = Audit.basic
      audit.message = "Exported Indicator #{self.title.presence || self.stix_id} had its classification changed from #{old} to #{nw} in #{exp.system.upcase}"
      audit.audit_type = :export
      audit.audit_subtype = :modify
      audit.item = self
      self.audits << audit
      exp.status = :active
      exp.set_cached_values(self)
      exp.save
    end
  end

  def prefix_with_portion_marking(text,portion_marking)
    if Setting.CLASSIFICATION == true
      # Pass the string through as-is if portion marking and/or the
      # string are not set properly, null, empty, etc.
      if text.nil? || text.length == 0
        text
      else
        if portion_marking.nil? || portion_marking.length == 0
          portion_marking = 'TS'
        end
        # Prefix the text string with the portion marking.
        "(" + portion_marking + ") " + text
      end
    else
      # Portion marking display is disabled on this systems so pass
      # through the string unchanged.
      text
    end
  end

  def need_comma(value)
    if value.length>0
      value+=', '
    end
    value
  end

  def set_observable_value
    value = ""
    if self.observables.length==0
      update_column(:observable_type,"")
      update_column(:observable_value,"")
    else
      write_type = ""
      write_value = ""
      write_value2 = ""
      self.observables.each do |observable|
        next if observable.object.blank?
        
        type = observable.remote_object_type
        value = ""
        value2 = ""

        if !observable.object.portion_marking.present? && observable.object.respond_to?(:set_portion_marking)
          observable.object.set_portion_marking
        end

        # Email Message
        if type == "EmailMessage"
          write_type=need_comma(write_type)+"Email Message"
          names = ["From","Reply-To","Sender","Subject"]
          attributes= ["from_normalized","reply_to_normalized","sender_normalized","subject"]

          # Build the email display information for people with view_pii_fields permission
          (0..3).each { |i|
            if observable.email_message[attributes[i]].present?
              if value.length>0
                value << " | "
              end
              value << names[i] + ": " + observable.email_message[attributes[i]]
            end
          }
          value = prefix_with_portion_marking(value, observable.email_message.portion_marking)

          # Build the email display information for people without view_pii_fields permission
          if observable.email_message['subject'].blank?
            value2 << 'Subject: [No Subject Specified]'
          else
            value2 << "Subject: " + observable.email_message['subject']
          end

        # Address
        elsif type == "Address"
          write_type=need_comma(write_type)+"Address"

          value = observable.address.address_value_normalized.to_s if observable.address.address_value_normalized.present?
          value = prefix_with_portion_marking(value, observable.address.portion_marking)
        # DNS Query
        elsif type == "DnsQuery"
          write_type=need_comma(write_type) + "DNS Query"

          value << observable.dns_query.display_name if observable.dns_query.present?
          value = prefix_with_portion_marking(value, observable.dns_query.portion_marking)
        # DNS Record
        elsif type == "DnsRecord"
          write_type=need_comma(write_type)+"DNS Record"
          
          value << "Address: " + observable.dns_record.address_value_normalized + " | " if observable.dns_record.address_value_normalized.present?
          value << "Address Class: " + observable.dns_record.address_class + " | " if observable.dns_record.address_class.present?
          value << "Domain: " + observable.dns_record.domain_normalized + " | " if observable.dns_record.domain_normalized.present?
          value << "Entry Type: " + observable.dns_record.entry_type if observable.dns_record.entry_type.present?
          
          value = prefix_with_portion_marking(value, observable.dns_record.portion_marking)

        # Domain
        elsif type == "Domain"
          write_type=need_comma(write_type)+"Domain"
          
          value << observable.domain.name if observable.domain.name.present?
          #value << " | Condition: " + observable.domain.name_condition if observable.domain.name_condition.present?

          value = prefix_with_portion_marking(value, observable.domain.portion_marking)
        
        #Hostname  
        elsif type == "Hostname"
          write_type=need_comma(write_type)+"Hostname"
          
          value << observable.hostname.hostname if observable.hostname.hostname.present?
          #value << " | Condition: " + observable.hostname.hostname_condition if observable.hostname.hostname_condition.present?
          value << " | Naming System: "+ observable.hostname.naming_system if observable.hostname.naming_system.present?
          value = prefix_with_portion_marking(value, observable.hostname.portion_marking)

        # Cybox File
        elsif type == "CyboxFile"
          write_type=need_comma(write_type)+"File"
          if !observable.file.file_name.nil? && observable.file.file_name.length>0
            value << "File Name: " + observable.file.file_name
          end
          if !observable.file.md5.nil? && observable.file.md5.length>0
            if value.length>0
              value << " | "
            end
            value << "MD5: " + observable.file.md5
          end
          value = prefix_with_portion_marking(value, observable.file.portion_marking)

        # HttpSession
        elsif type == "HttpSession"
          write_type=need_comma(write_type)+"HTTP Session"
          if !observable.http_session.user_agent.nil? && observable.http_session.user_agent.length > 0
            value << "User Agent: " + observable.http_session.user_agent
          end
          if !observable.http_session.domain_name.nil? && observable.http_session.domain_name.length > 0
            if value.length>0
              value << " | "
            end
            value << "Domain Name: " + observable.http_session.domain_name
            if !observable.http_session.port.nil? && observable.http_session.port.length > 0
              if value.length>0
                value << " | "
              end
              value << "Port: " + observable.http_session.port
            end
          end
          if !observable.http_session.referer.nil? && observable.http_session.referer.length > 0
            if value.length>0
              value << " | "
            end
            value << "| Referer: " + observable.http_session.referer
          end
          if !observable.http_session.pragma.nil? && observable.http_session.pragma.length > 0
            if value.length>0
              value << " | "
            end
            value << "| Pragma: " + observable.http_session.pragma
          end
          value = prefix_with_portion_marking(value, observable.http_session.portion_marking)

        # Link
        elsif type == "Link"
          write_type=need_comma(write_type)+"Link"
          if !observable.link.uri.uri.nil? && observable.link.uri.uri.length > 0
            value << observable.link.uri.uri
          end
          if !observable.link.label.nil? && observable.link.label.length > 0
            if value.length>0
              value << " "
            end
            value << '"' + observable.link.label + '"'
          end
          value = prefix_with_portion_marking(value, observable.link.portion_marking)

        # Cybox Mutex
        elsif type == "CyboxMutex"
          write_type=need_comma(write_type)+"Mutex"
          if !observable.mutex.name.nil? && observable.mutex.name.length > 0
            value << observable.mutex.name
          end
          value = prefix_with_portion_marking(value, observable.mutex.portion_marking)

        # Network Connection
        elsif type == "NetworkConnection"
          write_type=need_comma(write_type)+"Network Connection"
          if !observable.network_connection.source_socket_address.nil? or
             !observable.network_connection.source_socket_hostname.nil? or
             !observable.network_connection.source_socket_port.nil?
            value << "Source: "
            spoofed = ""

            if observable.network_connection.source_socket_address.present?
              value << observable.network_connection.source_socket_address
              if observable.network_connection.source_socket_is_spoofed
                spoofed = " (Spoofed)"
              end
            elsif !observable.network_connection.source_socket_hostname.nil?
              value << observable.network_connection.source_socket_hostname
            end
            if observable.network_connection.source_socket_port.present?
              value << ":" + observable.network_connection.source_socket_port
            end
            if observable.network_connection.layer4_protocol.present?
              value << "/" + observable.network_connection.layer4_protocol
            end
            value << spoofed
          end

          if !observable.network_connection.dest_socket_address.nil? or
             !observable.network_connection.dest_socket_hostname.nil? or
             !observable.network_connection.dest_socket_port.nil?
            if value.length>0
              value << " | "
            end

            value << "Destination: "
            spoofed = ""
            if !observable.network_connection.dest_socket_address.nil?
              value << observable.network_connection.dest_socket_address
              if observable.network_connection.dest_socket_is_spoofed
                spoofed = " (Spoofed)"
              end
            elsif !observable.network_connection.dest_socket_hostname.nil?
              value << observable.network_connection.dest_socket_hostname
            end
            if !observable.network_connection.dest_socket_port.nil?
              value << ":" + observable.network_connection.dest_socket_port
            end
            if observable.network_connection.layer4_protocol.present?
              value << "/" + observable.network_connection.layer4_protocol
            end
            value << spoofed
          end
          value = prefix_with_portion_marking(value, observable.network_connection.portion_marking)

        #port
        elsif type == "Port"
          write_type=need_comma(write_type)+"Port"
          
          value << "Port: " + observable.port.port + " | " if observable.port.port.present?
          value << "Layer4 Protocol: " + observable.port.layer4_protocol if observable.port.layer4_protocol.present?
          value = prefix_with_portion_marking(value, observable.port.portion_marking)
          
        # Registry
        elsif type == "Registry"
          write_type=need_comma(write_type)+"Registry"
          value << "Hive: " + observable.registry.hive + " | " if observable.registry.hive.present?
          value << "Key: " + observable.registry.key if observable.registry.key.present?
          value = prefix_with_portion_marking(value, observable.registry.portion_marking)

        # Socket Address
        elsif type == "SocketAddress"
          write_type=need_comma(write_type)+"Socket Address"
          value << observable.socket_address.display_name
          value = prefix_with_portion_marking(value, observable.socket_address.portion_marking)

        # Uri
        elsif type == "Uri"
          write_type=need_comma(write_type)+"URI"
          value << observable.uri.uri if observable.uri.uri.present?
          value = prefix_with_portion_marking(value, observable.uri.portion_marking)
        end
        write_value=need_comma(write_value)+value
        if value2.length > 0
          write_value2=need_comma(write_value2)+value2
        else
          write_value2=need_comma(write_value2)+value
        end
      end
      # If we have any email message observables linked to this indicator, we
      # need to add the non-pii version of the data so the filter can display
      # the proper one
      if write_type.include? "Email Message"
        if !write_value.include?(write_value2)
          write_value = write_value + "\n\n" + write_value2
        end
      end

      update_column(:observable_type,write_type)
      # for some reason update_column is not saving a value on clobs with oracle
      update_attribute(:observable_value,write_value)
    end
  end
  
  def set_threat_actor_value
    if self.fo_threat_actors.length==0
      update_attribute(:threat_actor_id,"") if !self.threat_actor_id.nil?
      update_attribute(:threat_actor_title,"") if !self.threat_actor_title.nil?
    else
      write_title = ""
      write_id = ""
      self.fo_threat_actors.each do |threat_actor|
        title = ""
        title << threat_actor.title if threat_actor.title.present?
        title =  prefix_with_portion_marking(title, threat_actor.portion_marking)
        write_title = need_comma(write_title) + title
        write_id = need_comma(write_id) + threat_actor.stix_id
      end
      
      update_attribute(:threat_actor_id, write_id)
      update_attribute(:threat_actor_title, write_title)
    end
  end

  def update_is_ais(fd_ais)
    update_column(:is_ais, fd_ais)
  end

private

  def audit_tag_removal(item)
    audit = Audit.basic
    audit.message = "Tag removed '#{item.name}' from Indicator '#{self.stix_id}'"
    audit.audit_type = :untag
    tag_audit = audit.dup
    tag_audit.item = item
    item.audits << tag_audit
    obj_audit = audit.dup
    obj_audit.item = self
    self.audits << obj_audit
  end

  def audit_threat_actor_removal(item)
    audit = Audit.basic
    audit.message = "Threat Actor removed '#{item.title}' from Indicator '#{self.stix_id}'"
    audit.audit_type = :remove_threat_actor
    tag_audit = audit.dup
    tag_audit.item = item
    item.audits << tag_audit
    obj_audit = audit.dup
    obj_audit.item = self
    self.audits << obj_audit
  end
  
  def audit_course_of_action_removal(item)
    audit = Audit.basic
    audit.message = "Course Of Action removed '#{item.title}' from Indicator '#{self.stix_id}'"
    audit.audit_type = :remove_course_of_action
    tag_audit = audit.dup
    tag_audit.item = item
    item.audits << tag_audit
    obj_audit = audit.dup
    obj_audit.item = self
    self.audits << obj_audit
  end

  def audit_ttp_removal(item)
    audit = Audit.basic
    audit.message = "TTP removed '#{item.stix_id}' from Indicator '#{self.stix_id}'"
    audit.audit_type = :indicator_ttp_unlink
    other_audit = audit.dup
    other_audit.item = item
    item.audits << other_audit
    obj_audit = audit.dup
    obj_audit.item = self
    self.audits << obj_audit
  end

  def user_presence
    self.created_by_user ||= User.current_user
    self.updated_by_user ||= User.current_user

    if self.created_by_user.blank?
      errors.add(:created_by_user,"can't be blank")
      errors.add(:created_by_organization,"can't be blank")
      return
    end

    self.created_by_organization ||= User.current_user.organization
  end

  def indicator_scoring_types
    if self.timelines != nil && Indicator::TIMELINES.select {|e| e[:name] == self.timelines}.blank?
      errors.add(:timelines, "Selected type is not a valid type")
    end

    if self.source_of_report != nil && Indicator::SOURCE_OF_REPORT.select {|e| e[:name] == self.source_of_report}.blank?
      errors.add(:source_of_report, "Selected type is not a valid type")
    end

    if self.target_of_attack != nil && Indicator::TARGET_OF_ATTACK.select {|e| e[:name] == self.target_of_attack}.blank?
      errors.add(:target_of_attack, "Selected type is not a valid type")
    end

    if self.target_scope != nil && Indicator::TARGET_SCOPE.select {|e| e[:name] == self.target_scope}.blank?
      errors.add(:target_scope, "Selected type is not a valid type")
    end

    if self.actor_attribution != nil && Indicator::ACTOR_ATTRIBUTION.select {|e| e[:name] == self.actor_attribution}.blank?
      errors.add(:actor_attribution, "Selected type is not a valid type")
    end

    if self.actor_type != nil && Indicator::ACTOR_TYPE.select {|e| e[:name] == self.actor_type}.blank?
      errors.add(:actor_type, "Selected type is not a valid type")
    end

    if self.modus_operandi != nil && Indicator::MODUS_OPERANDI.select {|e| e[:name] == self.modus_operandi}.blank?
      errors.add(:modus_operandi, "Selected type is not a valid type")
    end
  end

  def update_markings(attributes)
    return true if attributes.blank?
    return false if self.new_record?
    marking = StixMarking.find_by_stix_id(attributes[:stix_id])
    return false unless marking
    if marking.isa_marking_structures.present? && attributes[:isa_marking_structures_attributes].present?
      attributes[:isa_marking_structures_attributes].each do |attr|
        isa = marking.isa_marking_structures.select {|i| i.stix_id == attr[:stix_id]}.first
        attr.merge!(id: isa.id)
      end
    end
    false
  end

  def remove_exports
    begin
      self.exported_indicators.with_deleted.destroy_all
    rescue
      false
    end
  end

end
