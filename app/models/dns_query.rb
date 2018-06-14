class DnsQuery < ActiveRecord::Base

  self.table_name = "cybox_dns_queries"

  # You need this naming module because the observable audit calls on the display_name attribute
  module Naming
    def display_name
      value = ''

      value += 'Questions: ' + self.question_normalized_cache + ' | ' if self.question_normalized_cache.present?
      value += 'Answers: ' + self.answer_normalized_cache + ' | ' if self.answer_normalized_cache.present?
      value += 'Authorities: ' + self.authority_normalized_cache + ' | ' if self.authority_normalized_cache.present?
      value += 'Additional: ' + self.additional_normalized_cache + ' | ' if self.additional_normalized_cache.present?
      
      if value.blank?
        value = "#{self.class.to_s.tableize.singularize.titleize}, Cybox Object ID: #{cybox_object_id}" if self.cybox_object_id.present?
      end

      return value
    end
  end

  include Auditable
  include DnsQuery::Naming
  include Guidable
  include Cyboxable
  include Ingestible
  include AcsDefault
  include Serialized
  include Transferable

  has_many :parameter_observables, -> { where remote_object_type: 'DnsQuery' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
  has_many :course_of_actions, through: :parameter_observables

  has_many :observables, -> { where remote_object_type: 'DnsQuery' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, dependent: :destroy

  has_many :indicators, through: :observables
  has_many :ind_course_of_actions, through: :indicators, class_name: 'CourseOfAction', source: :course_of_actions

  has_many :dns_query_resource_records, primary_key: :cybox_object_id, foreign_key: :dns_query_id, dependent: :destroy
  has_many :resource_records, through: :dns_query_resource_records, before_remove: :audit_obj_removal
  has_many :dns_records, through: :resource_records

  has_many :answer_resource_records,-> {where(record_type: 'Answer Resource Record')}, through: :dns_query_resource_records, class_name: 'ResourceRecord', source: :resource_record
  has_many :authority_resource_records,-> {where(record_type: 'Authority Resource Record')}, through: :dns_query_resource_records, class_name: 'ResourceRecord', source: :resource_record
  has_many :additional_records,-> {where(record_type: 'Additional Record')}, through: :dns_query_resource_records, class_name: 'ResourceRecord', source: :resource_record

  has_many :dns_query_questions, primary_key: :cybox_object_id, foreign_key: :dns_query_id, dependent: :destroy
  has_many :questions, through: :dns_query_questions, before_remove: :audit_obj_removal
  has_many :uris, through: :questions

  has_many :layer_seven_connection_dns_queries, primary_key: :cybox_object_id, foreign_key: :dns_query_id, dependent: :destroy
  has_many :layer_seven_connections, through: :layer_seven_connection_dns_queries

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  after_commit :set_observable_value_on_indicator

  after_save :set_object_caches

  CLASSIFICATION_CONTAINER_OF = [:questions, :resource_records]

  def stix_packages
    packages = []

    packages |= self.course_of_actions.collect(&:stix_packages).flatten if self.course_of_actions.present?
    packages |= self.indicators.collect(&:stix_packages).flatten if self.indicators.present?

    packages
  end
    
  # Trickles down the disseminated feed value to all of the associated objects
  def trickledown_feed
    begin
      associations = ["questions", "resource_records"]
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
    x = DnsQuery.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "DNS Query of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x = obj.cybox_object_id.nil? ? nil : DnsQuery.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
      if x.present? 
        x.destroy
        x = nil
      end
    end

    if x.present?
      # Destroy all existing STIX markings to be re-ingested.
      x.stix_markings.destroy_all
      x.resource_records.destroy_all
      x.questions.destroy_all
    end

    x ||= DnsQuery.new
    HumanReview.adjust(obj, uploader)
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end

    # non ais attributes
    #x.transaction_id = obj.transaction_id if obj.respond_to?(:transaction_id)
    #x.date_ran = obj.date_ran if obj.respond_to?(:date_ran)
    #x.service_used = obj.service_used if obj.respond_to?(:service_used)
    #x.successful = obj.successful if obj.respond_to?(:successful)
    x.read_only = uploader.read_only
    x
  end

  def question_guids=(guids)
    self.question_ids = Question.where(guid: guids).pluck(:id)
  end

  def resource_record_guids=(guids)
    self.resource_record_ids = ResourceRecord.where(guid: guids).pluck(:id)
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

  def set_object_caches
    if self.questions.present?
      cache_value = self.questions.map{|q| (!q.qname_cache.nil? && q.qname_cache.length>0) ? q.qname_cache : q.guid}.to_sentence
      if cache_value.length > 255
        self.update_column(:question_normalized_cache, cache_value[0..251] + "...")
      else
        self.update_column(:question_normalized_cache, cache_value)
      end
    else
      self.update_column(:question_normalized_cache, "")
    end

    if self.answer_resource_records.present?
      cache_value = self.answer_resource_records.map(&:dns_record_cache).to_sentence
      if cache_value.length > 255
        self.update_column(:answer_normalized_cache, cache_value[0..251] + "...")
      else
        self.update_column(:answer_normalized_cache, cache_value)
      end
    else
      self.update_column(:answer_normalized_cache, "")
    end

    if self.authority_resource_records.present?
      cache_value = self.authority_resource_records.map(&:dns_record_cache).to_sentence
      if cache_value.length > 255
        self.update_column(:authority_normalized_cache, cache_value[0..251] + "...")
      else
        self.update_column(:authority_normalized_cache, cache_value)
      end
    else
      self.update_column(:authority_normalized_cache, "")
    end

    if self.additional_records.present?
      cache_value = self.additional_records.map(&:dns_record_cache).to_sentence
      if cache_value.length > 255
        self.update_column(:additional_normalized_cache, cache_value[0..251] + "...")
      else
        self.update_column(:additional_normalized_cache, cache_value)
      end
    else
      self.update_column(:additional_normalized_cache, "")
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

  # The following 3 methods are for proper matching of IP addresses
  def map_address_for_answer_normalized_cache
    match=nil
    if self.answer_normalized_cache
      match=self.answer_normalized_cache.match('Address: ([\d\.\/]+)')
      if match
        match=match[1]
      end
    end
    match
  end

  def map_address_for_authority_normalized_cache
    if self.authority_normalized_cache
      match=self.authority_normalized_cache.match('Address: ([\d\.\/]+)')
      if match
        match=match[1]
      end
    end
    match
  end

  def map_address_for_additional_normalized_cache
    if self.additional_normalized_cache
      match=self.additional_normalized_cache.match('Address: ([\d\.\/]+)')
      if match
        match=match[1]
      end
    end
    match
  end

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    time :created_at, stored: false
    time :updated_at, stored: false
    text :cybox_object_id, as: :text_exactm
    text :question_normalized_cache
    text :answer_normalized_cache
    text :authority_normalized_cache
    text :additional_normalized_cache
    text :map_address_for_answer_normalized_cache, as: :text_ipm
    text :map_address_for_authority_normalized_cache, as: :text_ipm
    text :map_address_for_additional_normalized_cache, as: :text_ipm
    text :guid, as: :text_exact
    string :question_normalized_cache
    string :answer_normalized_cache
    string :authority_normalized_cache
    string :additional_normalized_cache
    string :cybox_object_id
    string :portion_marking, stored: false

  end
end
