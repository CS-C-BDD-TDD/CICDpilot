class Uri < ActiveRecord::Base
  module RawAttribute
    module Writers
      def uri_raw=(value)
        write_attribute(:uri_raw, nil)
        write_attribute(:cybox_hash, nil)
        write_attribute(:uri_normalized, nil)
        write_attribute(:uri_type, nil)
        write_attribute(:uri_normalized_sha256, nil)
        write_attribute(:uri_short, nil)
        unless value.nil?
          write_attribute(:cybox_hash, CyboxHash.generate(normalized_value(value)))
          write_attribute(:uri_normalized, normalized_value(value))
          write_attribute(:uri_type, 'URL')
          write_attribute(:uri_normalized_sha256, Digest::SHA256.hexdigest(normalized_value(value)))
          write_attribute(:uri_short, normalized_value(value)[0, 255])
        end
        write_attribute(:uri_raw, value)
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
      return uri_raw
    end

    def display_class_name
	    "URI"
    end
  end

  self.table_name = "cybox_uris"

  include Auditable
  include Uri::RawAttribute::Writers
  include Uri::Normalize
  include Uri::Naming
  include Guidable
  include Cyboxable
  include Ingestible
  include AcsDefault
  include Serialized
  include ClassifiedObject
  include Transferable

  CLASSIFICATION_CONTAINED_BY = [:links, :parameter_observables, :course_of_actions, :ind_course_of_actions, 
                                 :email_uris, :email_messages, :indicators, :question_uris, :questions ]
  
  has_many :observables, -> { where remote_object_type: 'Uri' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, dependent: :destroy
  has_many :links, primary_key: :cybox_object_id, foreign_key: :uri_object_id
  
  has_many :parameter_observables, -> { where remote_object_type: 'Uri' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
  has_many :course_of_actions, through: :parameter_observables
  has_many :ind_course_of_actions, through: :indicators, class_name: 'CourseOfAction', source: :course_of_actions
  
  has_many :email_uris, primary_key: :guid
  has_many :email_messages, through: :email_uris
  has_many :indicators, through: :observables

  has_many :question_uris, primary_key: :cybox_object_id, foreign_key: :uri_id, dependent: :destroy
  has_many :questions, through: :question_uris

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  alias_attribute :uri, :uri_normalized
  alias_attribute :uri_input, :uri_raw

  validates_presence_of :uri
  validates_uniqueness_of :uri_normalized_sha256, :message => "cannot match a URI already in the system", unless: :duplication_needed?
  after_commit :set_observable_value_on_indicator 
  
  def self.ingest(uploader, obj, parent = nil)
    x = Uri.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "URI of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x = obj.cybox_object_id.nil? ? nil : Uri.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
    end

    if x.present?
      # Destroy all existing STIX markings to be re-ingested.
      x.stix_markings.destroy_all
    end

    x ||= Uri.new
    HumanReview.adjust(obj, uploader)
    x.uri_raw = obj.name_raw
    x.uri_condition = obj.uri_condition
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end
    x.read_only = uploader.read_only
    x
  end

  def stix_packages
    packages = []

    packages |= self.course_of_actions.collect(&:stix_packages).flatten if self.indicators.present?
    packages |= self.indicators.collect(&:stix_packages).flatten if self.indicators.present?
    packages |= self.links.collect(&:stix_packages).flatten if self.links.present?
    packages |= self.questions.collect(&:stix_packages).flatten if self.questions.present?

    packages.uniq
  end

  def duplication_needed?
    cybox_object_id && cybox_object_id.include?(Setting.READ_ONLY_EXT)
  end

  def set_cybox_hash
    value = self.uri_normalized
    if (self.uri_condition == 'StartsWith')
      value = '^' + value
    elsif (self.uri_condition == 'EndsWith')
      value += '$'
    end
    write_attribute(:cybox_hash, CyboxHash.generate(value))
  end

  def repl_params
    {
      :uri_input => uri_raw,
      :guid => guid,
      :cybox_object_id => cybox_object_id
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

  searchable :auto_index => ((defined?(Setting) && Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS)||0)==0 do
    text :uri, as: :text_uax
    string :uri
    string :uri_short
    text :uri_condition
    string :uri_condition
    text :guid, as: :text_exactm
    time :created_at, stored: false
    time :updated_at, stored: false
    text :cybox_object_id, as: :text_exact
    string :cybox_object_id
    string :portion_marking, stored: false

  end
end
