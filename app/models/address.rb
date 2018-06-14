class Address < ActiveRecord::Base
  require 'csv'

  module RawAttribute
    module Writers
      def address_value_raw=(value)
        # If a category is set, the address value will be validated to ensure
        # the address value is valid for the category. If a category is not
        # set, attempt to determine if the raw address value is valid for
        # either the ipv4-addr or ipv6-addr category, setting the category,
        # and proceeding accordingly if so determined.
        validated_category = nil
        if self.category.present?
          case self.category
            when 'ipv4-addr'
              validated_category =
                  self.category if Address.valid_ipv4_value?(value)
            when 'ipv6-addr'
              validated_category =
                  self.category if Address.valid_ipv6_value?(value)
            when 'e-mail'
              validated_category =
                  self.category if Address.valid_email_address?(value)
            else
              # Default category validation for categories without an
              # explicitly-defined case handles above consists of mere
              # validation that the category is allowed by STIX.
              validated_category = self.category if
                  Address.valid_address_category?(self.category)
          end
        else
          validated_category = 'ipv4-addr' if Address.valid_ipv4_value?(value)
          validated_category = 'ipv6-addr' if validated_category.nil? &&
              Address.valid_ipv6_value?(value)
        end

        # Perform setter actions based on the validated category. If the
        # category failed validation and methods to detect the category based
        # on the raw address value, validated_category will be nil.
        case validated_category
          when 'ipv4-addr'
            write_attribute(:address_value_normalized, Address.normalized_ipv4_value(value))
            write_attribute(:cybox_hash, CyboxHash.generate(Address.normalized_ipv4_value(value)))
            ip = IPAddress::IPv4.new(value.strip)
            write_attribute(:ip_value_calculated_start, ip.network.to_i)
            write_attribute(:ip_value_calculated_end, ip.broadcast.to_i)
          when 'ipv6-addr'
            write_attribute(:address_value_normalized, Address.normalized_ipv6_value(value))
            write_attribute(:cybox_hash, CyboxHash.generate(Address.normalized_ipv6_value(value)))
            write_attribute(:ip_value_calculated_start, nil)
            write_attribute(:ip_value_calculated_end, nil)
          when 'e-mail'
            write_attribute(:address_value_normalized, Address.normalized_email_address(value))
            write_attribute(:cybox_hash, CyboxHash.generate(Address.normalized_email_address(value)))
            write_attribute(:ip_value_calculated_start, nil)
            write_attribute(:ip_value_calculated_end, nil)
          else
            if value.present?
              write_attribute(:address_value_normalized, value.strip.downcase)
              write_attribute(:cybox_hash, CyboxHash.generate(value.strip.downcase))
            end
            write_attribute(:ip_value_calculated_start, nil)
            write_attribute(:ip_value_calculated_end, nil)
        end

        # Write the actual validated category or nil if the category failed
        # validation.
        write_attribute(:category, validated_category)
        # The raw address value is always written. If support for the category
        # type is not fully implemented yet, the normalized address value
        # will be set to nil and can only be accessed via the raw address value.
        write_attribute(:address_value_raw, value)
      end

      def first_date_seen_raw=(value)
        begin
          write_attribute(:first_date_seen_raw, value)
          write_attribute(:first_date_seen, nil)
          return if value.blank?
          write_attribute(:first_date_seen, DateTime.parse(value.to_s))
        rescue ArgumentError => e
          ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
        end
      end

      def last_date_seen_raw=(value)
        begin
          write_attribute(:last_date_seen_raw, value)
          write_attribute(:last_date_seen, nil)
          return if value.blank?
          write_attribute(:last_date_seen, DateTime.parse(value.to_s))
        rescue ArgumentError => e
          ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
        end
      end
    end
  end

  module Validations
    def self.included(base)
      base.instance_eval do
        validate :valid_category
        validate :valid_address
        def self.valid_ipv4_value?(raw)
          return unless raw.present?
          begin
            IPAddress::IPv4.new(raw.strip)
            true
          rescue ArgumentError
            false
          end
        end
        def self.valid_ipv6_value?(raw)
          return unless raw.present?
          begin
            IPAddress::IPv6.new(raw.strip)
            true
          rescue ArgumentError
            false
          end
        end
        def self.valid_email_address?(raw)
          return unless raw.present?
          /\A[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}\z/i.match(raw) ?
              true : false
        end
        def self.valid_address_category?(category_value)
          return unless category_value.present?
          return Stix::Native::CyboxAddress::ADDRESS_CATEGORIES.
              include?(category_value)
        end
      end
      def valid_address
        if address_value_raw.blank?
          errors.add(:address, "cannot be blank")
          return
        end
        if category.present?
          case category
            when 'ipv4-addr'
              unless Address.valid_ipv4_value?(address_value_raw)
                errors.add(:address, "`#{address_value_raw}` is not valid")
                return
              end
            when 'ipv6-addr'
              unless Address.valid_ipv6_value?(address_value_raw)
                errors.add(:address, "`#{address_value_raw}` is not valid")
                return
              end
            when 'e-mail'
              unless Address.valid_email_address?(address_value_raw)
                errors.add(:address, "`#{address_value_raw}` is not valid")
              end
          end
        end
      end
      def valid_category
        if category.blank?
          errors.add(:category, 'cannot be blank')
          errors.add(:address, 'is invalid')
          return
        end
        unless Address.valid_address_category?(category)
          errors.add(:category ,"`#{category}` is not valid")
        end
      end
    end
  end

  module Normalize
    def self.included(base)
      base.instance_eval do
        def self.normalized_ipv4_value(raw)
          return raw if raw.nil?
          if Address.valid_ipv4_value?(raw)
            IPAddress::IPv4.new(raw.strip.gsub(/\/32$/,'')).to_string
          else
            nil
          end
        end

        def self.normalized_ipv6_value(raw)
          return raw if raw.nil?
          if Address.valid_ipv6_value?(raw)
            IPAddress::IPv6.new(raw.strip).to_string
          else
            nil
          end
        end

        def self.normalized_email_address(raw)
          return raw if raw.nil?
          raw.strip.downcase
        end
      end
    end
  end

  module Naming
    def display_name
      return address_value_raw
    end

    def repl_params
      {
        address_input: address_value_raw,
        guid: guid,
        cybox_object_id: cybox_object_id
      }
    end
  end

  has_one :gfi, -> { where remote_object_type: 'Address' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, :dependent => :destroy, :autosave => true
  
  self.table_name = "cybox_addresses"
  include Auditable
  include Address::RawAttribute::Writers
  include Address::Validations
  include Address::Normalize
  include Address::Naming
  include Guidable
  include Cyboxable
  include Ingestible
  include Gfiable
  include AcsDefault
  include Serialized
  include ClassifiedObject
  include Transferable

  CLASSIFICATION_CONTAINED_BY = [:dns_records, :course_of_actions, :ind_course_of_actions, :socket_addresses,
                                 :email_senders, :email_reply_tos, :email_froms, :email_x_ips, :socket_address_addresses,
                                 :indicators, :parameter_observables]

  has_many :email_senders, class_name: 'EmailMessage', primary_key: :cybox_object_id, foreign_key: :sender_cybox_object_id
  has_many :email_reply_tos, class_name: 'EmailMessage', primary_key: :cybox_object_id, foreign_key: :reply_to_cybox_object_id
  has_many :email_froms, class_name: 'EmailMessage', primary_key: :cybox_object_id, foreign_key: :from_cybox_object_id
  has_many :email_x_ips, class_name: 'EmailMessage', primary_key: :cybox_object_id, foreign_key: :x_ip_cybox_object_id

  has_many :socket_address_addresses, primary_key: :cybox_object_id, foreign_key: :address_id, dependent: :destroy
  has_many :socket_addresses, through: :socket_address_addresses

  has_many :observables, -> { where remote_object_type: 'Address' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, dependent: :destroy

  has_many :indicators, through: :observables
  has_many :ind_course_of_actions, through: :indicators, class_name: 'CourseOfAction', source: :course_of_actions

  has_many :parameter_observables, -> { where remote_object_type: 'Address' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
  has_many :course_of_actions, through: :parameter_observables
  
  has_many :dns_records, class_name: 'DnsRecord', primary_key: :cybox_object_id, foreign_key: :address_cybox_object_id
  
  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  scope :ipv4_ipv6_addresses,-> {where(category: ['ipv4-addr','ipv6-addr'])}

  alias_attribute :address, :address_value_normalized
  alias_attribute :address_input, :address_value_raw
  alias_attribute :address_c, :address_value_normalized_c

  validates_uniqueness_of :address, :message => "cannot match an Address already in the system", if: -> obj { !(obj.duplication_needed? || obj.address_nil?) }

  validate :immutable_address, on: :update

  default_scope {order(updated_at: :desc)}
  
  after_commit :set_observable_value_on_indicator
  after_save :update_email_portion_markings
  after_save :update_dns_record_portion_markings

  def self.ingest(uploader, obj, parent = nil)
    case obj.category
      when 'ipv4-addr'
        if !Address.valid_ipv4_value?(obj.address_value)
          IngestUtilities.add_warning(uploader, "Address of category #{obj.category} has a bad value.  Skipping.")
          return nil
        end
      when 'ipv6-addr'
        if !Address.valid_ipv6_value?(obj.address_value)
          IngestUtilities.add_warning(uploader, "Address of category #{obj.category} has a bad value.  Skipping.")
          return nil
        end
      when 'e-mail'
        if !Address.valid_email_address?(obj.address_value)
          IngestUtilities.add_warning(uploader, "Address of category #{obj.category} has a bad value.  Skipping.")
          return nil
        end
    end

    x = Address.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "Address of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x = obj.cybox_object_id.nil? ? nil : Address.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
      if x.present? 
        x.destroy
        x = nil
      end
    end

    if x.present?
      # Destroy all existing STIX markings to be re-ingested.
      x.stix_markings.destroy_all
    end

    x ||= Address.new
    HumanReview.adjust(obj, uploader)
    x.category = obj.category if valid_address_category?(obj.category)
    x.address_value_raw = obj.address_value  # CYBOX Obj ID generated
    #x.apply_condition = obj.apply_condition
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end
    x.address_condition = obj.address_condition || "Equals"
    x.is_spoofed = obj.is_spoofed
    x.is_source = obj.is_source
    x.is_destination = obj.is_destination
    # vlan_name and vlan_num
    x.read_only = uploader.read_only
    x
  end

  def self.find_or_create_by(attributes, stix_markings = nil)
    # if it includes the raw but not the normalized lets normalize and try to find it
    if attributes.keys.include?(:address_value_raw) && !attributes.keys.include?(:address_value_normalized)
      a = attributes.slice!(:address_value_raw)

      if attributes[:address_value_raw].present?
        normalized = attributes[:address_value_raw]
        if Address.valid_ipv4_value?(normalized)
          normalized = Address.normalized_ipv4_value(normalized)
        elsif Address.valid_ipv6_value?(normalized)
          normalized = Address.normalized_ipv6_value(normalized)
        else
          normalized = normalized.strip.downcase
        end
        a[:address_value_normalized] = normalized
      end
    end

    add = Address.where(a).first

    if add.blank?
      add = Address.new(attributes)
      add.set_cybox_object_id
      add.set_guid
      add.address_condition = "Equals"
      
      if stix_markings.blank?
        stix_markings = Address.create_default_policy(add)
      else
        stix_markings.remote_object_id = add.guid
        stix_markings.remote_object_type = "Address"
        stix_markings.remote_object_field = nil
        stix_markings.save!
      end

      add.stix_markings << stix_markings

      if Address.valid_ipv4_value?(add.address_value_normalized)
        add.category = 'ipv4-addr'
      elsif Address.valid_ipv6_value?(add.address_value_normalized)
        add.category = 'ipv6-addr'
      elsif Address.valid_email_address?(add.address_value_normalized)
        add.category = 'e-mail'
      end

      begin
        add.save!
      rescue Exception => e
        ExceptionLogger.debug("[Address][find_or_create_by] #{e.to_s}")
      end

    else
      # if stix_markings are sent in need to check whos marking is more recent and keep that one
      if stix_markings.present? && add.stix_markings.present?
        begin
          if stix_markings.updated_at > add.stix_markings.first.updated_at
            add.stix_markings.first.destroy!
            stix_markings.remote_object_id = add.guid
            stix_markings.remote_object_type = "Address"
            stix_markings.remote_object_field = nil
            stix_markings.save!
          else
            stix_markings.destroy!
          end
        rescue Exception => e
          ExceptionLogger.debug("[Address][find_or_create_by] #{e.to_s}")
        end
      end
    end

    add
  end

  def stix_packages
    packages = []

    packages |= self.dns_records.collect(&:stix_packages).flatten if self.dns_records.present?
    packages |= self.course_of_actions.collect(&:stix_packages).flatten if self.course_of_actions.present?
    packages |= self.socket_addresses.collect(&:stix_packages).flatten if self.socket_addresses.present?
    packages |= self.email_senders.collect(&:stix_packages).flatten if self.email_senders.present?
    packages |= self.email_reply_tos.collect(&:stix_packages).flatten if self.email_reply_tos.present?
    packages |= self.email_froms.collect(&:stix_packages).flatten if self.email_froms.present?
    packages |= self.email_x_ips.collect(&:stix_packages).flatten if self.email_x_ips.present?
    packages |= self.indicators.collect(&:stix_packages).flatten if self.indicators.present?

    packages
  end

  def duplication_needed?
    cybox_object_id && cybox_object_id.include?(Setting.READ_ONLY_EXT)
  end

  def address_nil?
    address.nil?
  end
  
  def self.create_weather_map_data(csv_data)
    WeatherMapLogger.info("[AddressController][create_weather_map_data] Creating csv data ...")
    puts("[AddressController][create_weather_map_data] Creating csv data ...")
    total_good = 0
    total_rejects = 0
    rejects = []
    created_ids = []

    CSV.parse(csv_data) do |row|
      # skip blank lines
      next if row.count == 0
      next if row.count != 9
      normalized_value = Address.normalized_ipv4_value(row[0])
      wmd = Address.find_by_address(normalized_value).presence || Address.new
      wmd.address_value_raw = row[0] if wmd.new_record?
      wmd.iso_country_code = row[1]
      wmd.com_threat_score = row[2]
      wmd.gov_threat_score = row[3]
      wmd.combined_score = row[4]
      wmd.agencies_sensors_seen_on = row[5]
      wmd.first_date_seen_raw = row[6]
      wmd.last_date_seen_raw = row[7]
      wmd.category_list = row[8]

      unless wmd.stix_markings.present?
        isa_assertion = IsaAssertionStructure.new(AcsDefault::ASSERTION_DEFAULTS)
        isa_marking = IsaMarkingStructure.new(AcsDefault::MARKING_DEFAULTS)
        isa_privs = AcsDefault::PRIVS_DEFAULTS.collect do |priv|
          IsaPriv.new(priv)
        end
        stix_marking = StixMarking.new(
            is_reference: false
        )

        isa_assertion.cs_classification = 'U'

        stix_marking.isa_marking_structure = isa_marking
        stix_marking.isa_assertion_structure = isa_assertion
        stix_marking.isa_assertion_structure.isa_privs = isa_privs

        wmd.stix_markings << stix_marking

        wmd.portion_marking = 'U'
      end

      if wmd.valid?
        wmd.save
        #created_ids << wmd.id
        total_good = total_good + 1
        x = total_good % 1000
        puts("Loaded: #{total_good} at #{Time.now.to_s}") if x == 0
      else

        WeatherMapLogger.info("[AddressController][create_weather_map_data] rejected: #{wmd.errors.messages.to_s}")
        puts("[AddressController][create_weather_map_data] rejected: #{wmd.errors.messages.to_s}")
        #rejects << wmd
        total_rejects = total_rejects + 1
      end
    end
    puts("Total Good = #{total_good}, Rejects = #{total_rejects}")
    return total_good,rejects,created_ids
  rescue Exception => e
    WeatherMapLogger.info("[AddressController][create_weather_map_data] Exception: #{e.message}")
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

  def update_email_portion_markings
    return true if Setting.CLASSIFICATION == false

    self.email_senders.each do |em|
      em.update_address_portion_markings(self.portion_marking, :sender_normalized_c)
    end

    self.email_reply_tos.each do |em|
      em.update_address_portion_markings(self.portion_marking, :reply_to_normalized_c)
    end

    self.email_froms.each do |em|
      em.update_address_portion_markings(self.portion_marking, :from_normalized_c)
    end

    self.email_x_ips.each do |em|
      em.update_address_portion_markings(self.portion_marking, :x_originating_ip_c)
    end

    true
  end
  
  
  def update_dns_record_portion_markings
    return true if Setting.CLASSIFICATION == false
    
    self.dns_records.each do |dr|
      dr.update_address_portion_markings(self.portion_marking, :address_value_normalized_c)
    end

    true
  end

  def total_sightings
    cnt = 0
    cnt = indicators.collect{|ind| ind.sightings.size}.sum
    return cnt
  end

private

  # This is here to allow multiple indexes of the same field
  def map_address_for_email_index
    self.address
  end

  def set_observable_value_on_indicator
    self.indicators.each do |indicator|
      indicator.set_observable_value
    end
  end

  def immutable_address
    errors.add(:address, "cannot be modified") if self.changes.include?('address_input') || self.changes.include?('address_value_raw')
  end

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :address, as: :text_ip
    text :map_address_for_email_index, as: :text_emailuax # add this in if you want email category searches to happen on address
    string :address
    text :address_condition
    string :address_condition
    text :iso_country_code
    string :iso_country_code
    text :cybox_object_id, as: :text_exact
    string :cybox_object_id
    long :ip_value_calculated_start
    long :ip_value_calculated_end
    text :category_list
    string :category_list
    string :category
    text :guid, as: :text_exactm

    #Configure for Sunspot, but don't build indices for searching.  Needed for sorting while searching
    time :created_at, stored: false
    time :updated_at, stored: false
    time :first_date_seen, stored: false
    time :last_date_seen, stored: false
    integer :combined_score, stored: false
    string :portion_marking, stored: false
    
  end
end
