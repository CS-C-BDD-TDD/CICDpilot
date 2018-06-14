class Domain < ActiveRecord::Base
  require 'csv'
  
  module RawAttribute
    module Writers
      def name_raw=(value)
        write_attribute(:name_raw, nil)
        write_attribute(:name_normalized, nil)
        write_attribute(:root_domain, nil)
        unless value.nil?
          write_attribute(:name_normalized, normalized_value(value))
          host = DomainName(normalized_value(value))
          write_attribute(:root_domain, host.domain) if host.canonical?
        end
        write_attribute(:name_raw, value)
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

  module Normalize
    def normalized_value(raw)
      return raw if raw.nil?
      raw.strip.downcase
    end
  end

  module Naming
    def display_name
      return name_raw
    end
  end

  has_one :gfi, -> { where remote_object_type: 'Domain' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, :dependent => :destroy, :autosave => true
  self.table_name = "cybox_domains"

  include Auditable
  include Domain::RawAttribute::Writers
  include Domain::Normalize
  include Domain::Naming
  include Guidable
  include Cyboxable
  include Ingestible
  include Gfiable
  include AcsDefault
  include Serialized
  include Transferable

  has_many :observables, -> { where remote_object_type: 'Domain' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, dependent: :destroy
  has_many :indicators, through: :observables
  has_many :ind_course_of_actions, through: :indicators, class_name: 'CourseOfAction', source: :course_of_actions

  has_many :parameter_observables, -> { where remote_object_type: 'Domain' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
  has_many :course_of_actions, through: :parameter_observables

  has_many :dns_records, class_name: 'DnsRecord', primary_key: :cybox_object_id, foreign_key: :domain_cybox_object_id
  
  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  alias_attribute :name, :name_normalized
  alias_attribute :name_input, :name_raw
  alias_attribute :name_c, :name_normalized_c

  validates_presence_of :name
  validates_presence_of :name_condition
  validate :unique_name_create, on: :create
  validate :unique_name_update, on: :update
  after_commit :set_observable_value_on_indicator
  
  def stix_packages
    packages = []

    packages |= self.course_of_actions.collect(&:stix_packages).flatten if self.course_of_actions.present?
    packages |= self.indicators.collect(&:stix_packages).flatten if self.indicators.present?
    packages |= self.dns_records.collect(&:stix_packages).flatten if self.dns_records.present?

    packages
  end

  def self.ingest(uploader, obj, parent = nil)
    x = Domain.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "Domain of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x = obj.cybox_object_id.nil? ? nil : Domain.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
      if x.present? 
        x.destroy
        x = nil
      end
    end

    if x.present?
      # Destroy all existing STIX markings to be re-ingested.
      x.stix_markings.destroy_all
    end

    x ||= Domain.new
    HumanReview.adjust(obj, uploader)
    x.name_condition = obj.name_condition
    x.name_raw = obj.name_raw                # CYBOX Obj ID generated
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
    if attributes.keys.include?(:name_raw) && !attributes.keys.include?(:name_normalized)
      d = attributes.slice!(:name_raw)

      if attributes[:name_raw].present?
        normalized = attributes[:name_raw].strip.downcase

        d[:name_normalized] = normalized
      end
    end

    domain = Domain.where(d).first

    if domain.blank?
      domain = Domain.new(attributes)
      domain.set_cybox_object_id
      domain.set_guid
      domain.name_condition = "Equals"

      if stix_markings.blank?
        stix_markings = Domain.create_default_policy(domain)
      else
        stix_markings.remote_object_id = domain.guid
        stix_markings.remote_object_type = "Domain"
        stix_markings.remote_object_field = nil
        stix_markings.save!
      end

      domain.stix_markings << stix_markings

      begin
        domain.save!
      rescue StandardError => e
        ExceptionLogger.debug("[Domain][find_or_create_by] #{e.to_s}")
      end

    else
      # if stix_markings are sent in need to check whos marking is more recent and keep that one
      if stix_markings.present? && domain.stix_markings.present?
        begin
          if stix_markings.updated_at > domain.stix_markings.first.updated_at
            domain.stix_markings.first.destroy!
            stix_markings.remote_object_id = domain.guid
            stix_markings.remote_object_type = "Domain"
            stix_markings.remote_object_field = nil
            stix_markings.save!
          else
            stix_markings.destroy!
          end
        rescue Exception => e
          ExceptionLogger.debug("[Domain][find_or_create_by] #{e.to_s}")
        end
      end
    end

    domain
  end


  def set_cybox_hash
    value = self.name_normalized
    if (self.name_condition == 'StartsWith')
      value = '^' + value
    elsif (self.name_condition == 'EndsWith')
      value += '$'
    end

    write_attribute(:cybox_hash, CyboxHash.generate(value))
  end

  def repl_params
    {
      name_input: name,
      name_condition: name_condition,
      guid: guid,
      cybox_object_id: cybox_object_id
    }

  end

  def self.create_weather_map_data(csv_data)
    WeatherMapLogger.info("[DomainController][create_weather_map_data] Creating csv data ...")
    puts("[DomainController][create_weather_map_data] Creating csv data ...")
    total_good = 0
    total_rejects = 0
    rejects = []
    created_ids = []

    
    CSV.parse(csv_data) do |row|
      # skip blank lines
      next if row.count == 0
      next if row.count != 9 && row.count != 10
      normalized_name = row[0].nil? ? row[0] : row[0].strip.downcase
      wmd = Domain.find_by_name_normalized(normalized_name).presence || Domain.new
      wmd.name_raw = row[0] if wmd.new_record?
      wmd.iso_country_code = row[1]
      wmd.com_threat_score = row[2]
      wmd.gov_threat_score = row[3]
      wmd.combined_score = row[4]
      wmd.agencies_sensors_seen_on = row[5]
      wmd.first_date_seen_raw = row[6]
      wmd.last_date_seen_raw = row[7]
      wmd.category_list = row[8]
      wmd.name_condition = "Equals"

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
        WeatherMapLogger.info("[DomainController][create_weather_map_data] rejected: #{wmd.errors.messages.to_s}")
        puts("[DomainController][create_weather_map_data] rejected: #{wmd.errors.messages.to_s}")
        #rejects << wmd
        total_rejects = total_rejects + 1
      end
    end
    puts("Total Good = #{total_good}, Rejects = #{total_rejects}")
    return total_good,rejects,created_ids
  rescue Exception => e
    WeatherMapLogger.info("[DomainController][create_weather_map_data] Exception: #{e.message}")
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

  def unique_name_create
    matching_domains = Domain.where(name_normalized: self.name_normalized, name_condition: self.name_condition)
    errors.add(:name, "cannot match a Domain already in the system") if matching_domains.any?
  end

  def unique_name_update
    errors.add(:name, "cannot be modified") if self.changes.include? 'name_normalized'
    errors.add(:name_condition, "cannot be modified") if self.changes.include? 'name_condition'
    errors.add(:cybox_object_id, "cannot be modified") if self.changes.include? 'cybox_object_id'
  end

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :name_normalized, as: :name_domain
    string :name_normalized
    text :name_condition
    string :name_condition
    text :iso_country_code
    string :iso_country_code
    text :cybox_object_id, as: :text_exact
    string :cybox_object_id
    text :category_list
    string :category_list
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
