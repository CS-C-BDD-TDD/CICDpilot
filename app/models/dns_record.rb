class DnsRecord < ActiveRecord::Base

  module RawAttribute
    module Writers
      def domain_raw=(value, stix_markings=nil)
        write_attribute(:domain_raw, nil)
        write_attribute(:domain_normalized, nil)
        unless value.nil?
          in_domain = Domain.find_or_create_by({name_raw: value}, stix_markings)
          self.dns_domain = in_domain
        else
          write_attribute(:domain_normalized, normalized_domain(value))
          write_attribute(:domain_raw, value)
        end
      end

      def address_value_raw=(value, stix_markings = nil)
        write_attribute(:address_value_raw, nil)
        write_attribute(:address_value_normalized, nil)
        if value.present?
            in_address = Address.find_or_create_by({address_value_raw: value}, stix_markings)
            self.dns_address = in_address
        else
            write_attribute(:address_value_normalized, normalized_address(value))
            write_attribute(:address_value_raw, value)
        end
      end
      
      def dns_address=(address)
        if address.present? && address.class == Address
          self.link_address_audit(address) if address.address_value_raw != self.address_value_raw
          write_attribute(:address_value_normalized, normalized_address(address.address_value_raw))
          write_attribute(:address_value_raw, address.address_value_raw)
          write_attribute(:address_cybox_object_id, address.cybox_object_id)
          write_attribute(:address_value_normalized_c, address.portion_marking)
        end
      end

      def dns_domain=(domain)
        if domain.present? && domain.class == Domain
          self.link_domain_audit(domain) if domain.name_raw != self.domain_raw
          write_attribute(:domain_normalized, domain.name_normalized)
          write_attribute(:domain_raw, domain.name_raw)
          write_attribute(:domain_cybox_object_id, domain.cybox_object_id)
          write_attribute(:domain_normalized_c, domain.portion_marking)
        end
      end
    end
  end

  module Normalize
    def normalized_domain(raw)
      return raw if raw.nil?
      raw.strip.downcase
    end

    def normalized_address(raw)
      return raw if raw.nil?
      begin
        IPAddress::IPv6.new(raw).to_string
      rescue
        begin
          IPAddress::IPv4.new(raw).to_string
        rescue
          nil
        end
      end
    end
  end

  module Naming
    def display_name
      value = ''
      if self.address.present?
        value = "#{value} Address: #{address}"
      end
      if self.address_class.present?
        value = "#{value} Address Class: #{address_class}"
      end
      if self.domain_normalized.present?
        value = "#{value} Domain: #{domain_normalized}"
      end
      if self.entry_type.present?
        value = "#{value} Entry Type: #{entry_type}"
      end
      return value
    end

    def display_class_name
	    "DNS Record"
    end
  end

  has_one :gfi, -> { where remote_object_type: 'DnsRecord' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, :dependent => :destroy, :autosave => true
  
  self.table_name = "cybox_dns_records"

  include Auditable
  include DnsRecord::RawAttribute::Writers
  include DnsRecord::Normalize
  include DnsRecord::Naming
  include Guidable
  include Cyboxable
  include Ingestible
  include Gfiable
  include AcsDefault
  include Serialized
  include Transferable

  after_save :update_linked_indicators

  has_many :observables, -> { where remote_object_type: 'DnsRecord' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, dependent: :destroy
  has_many :indicators, through: :observables
  has_many :ind_course_of_actions, through: :indicators, class_name: 'CourseOfAction', source: :course_of_actions

  has_many :parameter_observables, -> { where remote_object_type: 'DnsRecord' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
  has_many :course_of_actions, through: :parameter_observables

  has_many :resource_record_dns_records, primary_key: :cybox_object_id, foreign_key: :dns_record_id, dependent: :destroy
  has_many :resource_records, through: :resource_record_dns_records

  has_many :answer_resource_records,-> {where(record_type: 'answer')}, through: :resource_record_dns_records, class_name: 'ResourceRecord', source: :resource_record
  has_many :authority_resource_records,-> {where(record_type: 'authority')}, through: :resource_record_dns_records, class_name: 'ResourceRecord', source: :resource_record
  has_many :additional_records,-> {where(record_type: 'additional')}, through: :resource_record_dns_records, class_name: 'ResourceRecord', source: :resource_record
  
  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  belongs_to :dns_address, class_name: 'Address', primary_key: :cybox_object_id, foreign_key: :address_cybox_object_id
  belongs_to :dns_domain, class_name: 'Domain', primary_key: :cybox_object_id, foreign_key: :domain_cybox_object_id
  
  alias_attribute :domain, :domain_normalized
  alias_attribute :domain_input, :domain_raw
  alias_attribute :address, :address_value_normalized
  alias_attribute :address_input, :address_value_raw
  alias_attribute :domain_c, :domain_normalized_c
  alias_attribute :address_c, :address_value_normalized_c

  validate :valid_address
  validate :valid_dns_record_type
  validates_presence_of :address_class
  validates_presence_of :domain_normalized
  validates_presence_of :entry_type
  after_commit :set_observable_value_on_indicator

  validates_length_of :record_name, :maximum => 255
  validates_length_of :ttl, :maximum => 255
  validates_length_of :flags, :maximum => 255
  validates_length_of :data_length, :maximum => 255
  
  CLASSIFICATION_CONTAINER_OF = [:dns_address,:dns_domain]

  DNSRecordTypes = [
    "A",
    "AAAA",
    "AFSDB",
    "APL",
    "AXFR",
    "CAA",
    "CDNSKEY",
    "CDS",
    "CERT",
    "CNAME",
    "DHCID",
    "DLV",
    "DNAME",
    "DNSKEY",
    "DS",
    "HIP",
    "IPSECKEY",
    "IXFR",
    "KEY",
    "KX",
    "LOC",
    "MX",
    "NAPTR",
    "NS",
    "NSEC",
    "NSEC3",
    "NSEC3PARAM",
    "OPT",
    "PTR",
    "RRSIG",
    "RP",
    "SIG",
    "SOA",
    "SRV",
    "SSHFP",
    "TA",
    "TKEY",
    "TLSA",
    "TSIG",
    "TXT"
  ]

  def stix_packages
    packages = []

    packages |= self.course_of_actions.collect(&:stix_packages).flatten if self.course_of_actions.present?
    packages |= self.indicators.collect(&:stix_packages).flatten if self.indicators.present?
    packages |= self.resource_records.collect(&:stix_packages).flatten if self.resource_records.present?

    packages
  end
  
  # Trickles down the disseminated feed value to all of the associated objects
  def trickledown_feed
    begin
      associations = ["dns_address", "dns_domain"]
      associations.each do |a|       
        object = self.send a
        if object.present? && self.feeds.present?
          object.update_column(:feeds, self.feeds) 
          object.try(:trickledown_feed)
        end
      end
    rescue Exception => e
      ex_msg = "Exception during trickledown_feed on: " + self.class.name    
      ExceptionLogger.debug("#{ex_msg}" + ". #{e.to_s}")
    end
  end   

  def self.ingest(uploader, obj, parent = nil)
    x = DnsRecord.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "DNS Record of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x = obj.cybox_object_id.nil? ? nil : DnsRecord.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
      if x.present? 
        x.destroy
        x = nil
      end
    end

    if x.present?
      # Destroy all existing STIX markings to be re-ingested.
      x.stix_markings.destroy_all
    end

    x ||= DnsRecord.new
    HumanReview.adjust(obj, uploader)
    x.address_class = obj.address_class
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end
    x.description = obj.description
    x.entry_type = obj.entry_type
    x.queried_date = obj.queried_date
    x.record_name = obj.record_name
    x.record_type = obj.record_type
    x.ttl = obj.ttl
    x.flags = obj.flags
    x.data_length = obj.data_length
    x.read_only = uploader.read_only

    # These two are now Objects, we will parse them seperatly
    # x.address_value_raw = obj.ip_address.address_value if obj.ip_address.present?
    # x.domain_raw = obj.name_raw
    
    x
  end

  # Special function for saving/updates preprocessing because of imbedded objects.
  def self.custom_save_or_update(*args)
    if args[0][:cybox_object_id].present?
      dns = DnsRecord.find_by_cybox_object_id(args[0][:cybox_object_id])
    end

    # let us first check if the addresses exist to know if we need to create them.
    # if the address is inputted but the address object doesnt exist we need to create it.
    if args[0][:address_input].present? && !Address.find_by_address_input(args[0][:address_input].downcase).present?
      # first see if we have custom markings.
      field_markings = args[0][:stix_markings_attributes].index {|x| x[:remote_object_field] == "address_value_normalized"} if args[0][:stix_markings_attributes].present?
      # if they exist use them
      begin
        if field_markings.present?
          markings = args[0][:stix_markings_attributes][field_markings]
          markings[:remote_object_field] = nil
          stix_markings = StixMarking.create(markings)
          Address.find_or_create_by({address_value_raw: args[0][:address_input].strip.downcase}, stix_markings)
          args[0][:stix_markings_attributes].delete(args[0][:stix_markings_attributes][field_markings])
        # if not we need to clone from the object of the dns object.
        else
          field_markings = Marking.remote_ids_from_args(args[0][:stix_markings_attributes].select {|x| x[:remote_object_field] == nil}.first)
          stix_markings = StixMarking.create(field_markings)
          Address.find_or_create_by({address_value_raw: args[0][:address_input].strip.downcase}, stix_markings)
        end
      rescue Exception => e
        if stix_markings.present? && stix_markings.remote_object_id.blank?
          stix_markings.destroy
        end
      end
    end

    # if the domain is inputted but the domain object doesnt exist we need to create it.
    if args[0][:domain_input].present? && !Domain.find_by_name(args[0][:domain_input].downcase).present?
      # first see if we have custom markings.
      field_markings = args[0][:stix_markings_attributes].index {|x| x[:remote_object_field] == "domain_normalized"} if args[0][:stix_markings_attributes].present?
      # if they exist use them
      begin
        if field_markings.present?
          markings = args[0][:stix_markings_attributes][field_markings]
          markings[:remote_object_field] = nil
          stix_markings = StixMarking.create(markings)
          Domain.find_or_create_by({name_raw: args[0][:domain_input].strip.downcase}, stix_markings)
          args[0][:stix_markings_attributes].delete(args[0][:stix_markings_attributes][field_markings])
        # if not we need to clone from the object of the dns object.
        else
          field_markings = Marking.remote_ids_from_args(args[0][:stix_markings_attributes].select {|x| x[:remote_object_field] == nil}.first)
          stix_markings = StixMarking.create(field_markings)
          Domain.find_or_create_by({name_raw: args[0][:domain_input].strip.downcase}, stix_markings)
        end
      rescue Exception => e
        if stix_markings.present? && stix_markings.remote_object_id.blank?
          stix_markings.destroy
        end
      end
    end

    if dns
      dns.update(args[0])
    else 
      dns = DnsRecord.create(args[0])
    end

    dns
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
    if address_value_raw.blank?
      errors.add(:address_value_normalized, "cannot be blank")
      return
    end
    unless Address.valid_ipv4_value?(address_value_raw) || Address.valid_ipv6_value?(address_value_raw)
      errors.add(:address_value_normalized,"`#{address_value_raw}` is not valid")
      return
    end
  end

  def valid_dns_record_type
    if self.record_type.present? && !DnsRecord::DNSRecordTypes.include?(self.record_type)
      errors.add(:record_type,"`#{self.record_type}` is not a valid dns record type")
    end
  end

  def set_cybox_hash
    fields_array = [self.address_value_normalized,
                    self.address_class,
                    self.domain_normalized,
                    self.entry_type]
    all_fields = String.new
    fields_array.each do |f|
      unless f.nil?
        all_fields += f
      end
    end

    write_attribute(:cybox_hash, CyboxHash.generate(all_fields))
  end

  def repl_params
    {:address_input => address_value_raw,
     :address_class => address_class,
     :domain_input => domain_value_raw,
     :entry_type => entry_type,
     :queried_date => queried_date,
     :cybox_object_id => cybox_object_id,
     :guid => guid,
     :record_name => record_name,
     :record_type => record_type,
     :ttl => ttl,
     :flags => flags,
     :data_length => data_length
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
          when 'address_class'
            sm.controlled_structure +=
                'cybox:Properties/DNSRecordObj:Address_Class/'
          when 'domain_normalized'
            sm.controlled_structure +=
                'cybox:Properties/DNSRecordObj:Domain_Name/'
          when 'entry_type'
            sm.controlled_structure +=
                'cybox:Properties/DNSRecordObj:Entry_Type/'
          when 'queried_date'
            sm.controlled_structure +=
                'cybox:Properties/DNSRecordObj:Queried_Date/'
          when 'record_name'
            sm.controlled_structure +=
                'cybox:Properties/DNSRecordObj:Record_Name/'
          when 'record_type'
            sm.controlled_structure +=
                'cybox:Properties/DNSRecordObj:Record_Type/'
          when 'ttl'
            sm.controlled_structure +=
                'cybox:Properties/DNSRecordObj:TTL/'
          when 'flags'
            sm.controlled_structure +=
                'cybox:Properties/DNSRecordObj:Flags/'
          when 'data_length'
            sm.controlled_structure +=
                'cybox:Properties/DNSRecordObj:Data_Length/'
          else
            sm.controlled_structure = nil
            return
        end
      end
      sm.controlled_structure += 'descendant-or-self::node()'
      sm.controlled_structure += "| #{sm.controlled_structure}/@*"
    end
  end
  
  def link_address_audit(item)
    audit = Audit.basic
    audit.message = "Address '#{item.cybox_object_id}' added to Dns Record '#{self.cybox_object_id}'"
    audit.audit_type = :dns_record_address_link
    other_audit = audit.dup
    other_audit.item = item
    item.audits << other_audit
    obj_audit = audit.dup
    obj_audit.item = self
    self.audits << obj_audit
  end

  def link_domain_audit(item)
    audit = Audit.basic
    audit.message = "Domain '#{item.cybox_object_id}' added to Dns Record '#{self.cybox_object_id}'"
    audit.audit_type = :dns_record_domain_link
    other_audit = audit.dup
    other_audit.item = item
    item.audits << other_audit
    obj_audit = audit.dup
    obj_audit.item = self
    self.audits << obj_audit
  end
  
  def update_address_portion_markings(portion_marking, col)
    update_attribute(col, portion_marking)
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

  def update_linked_indicators
    unless self.changes.empty?
      self.indicators.each do |i|
        audit = Audit.basic
        audit.message = "DNS Record observable updated"
        audit.details = self.changes.except("updated_at")
        audit.item = i
        audit.audit_type = :observable_update
        i.audits << audit
        i.updated_at = Time.now
        i.save
      end
    end
  end

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :address_value_normalized, as: :text_ipm
    string :address_value_normalized
    text :address_class
    string :address_class
    text :domain_normalized
    string :domain_normalized
    text :entry_type
    text :guid, as: :text_exactm
    time :created_at, stored: false
    time :updated_at, stored: false
    text :cybox_object_id, as: :text_exact
    string :cybox_object_id
    string :portion_marking, stored: false
    string :entry_type
    string :record_name
    string :record_type
    string :ttl
    string :flags
    string :data_length
    text :record_name
    text :record_type
    text :ttl
    text :flags
    text :data_length

  end
end
