class Question < ActiveRecord::Base

  self.table_name = "questions"

  include Auditable
  include Guidable
  include Ingestible
  include AcsDefault
  include Serialized
  include Transferable

  has_many :dns_query_questions, primary_key: :guid, foreign_key: :question_id, dependent: :destroy
  has_many :dns_queries, through: :dns_query_questions

  has_many :question_uris, primary_key: :guid, foreign_key: :question_id, dependent: :destroy
  has_many :uris, through: :question_uris, before_remove: :audit_obj_removal

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  before_save :set_object_caches
  after_save :set_portion_marking

  validates_length_of :qclass, :maximum => 255

  def stix_packages
    packages = []

    packages |= self.dns_queries.collect(&:stix_packages).flatten if self.dns_queries.present?

    packages
  end

  # Trickles down the disseminated feed value to all of the associated objects
  def trickledown_feed
    begin
      associations = ["uris"]
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
  
  def set_portion_marking
    return unless self.respond_to?(:portion_marking)
    return if @is_upload

    markings = self.uris.collect(&:portion_marking)

    highest = Classification.determine_highest_single(markings) unless markings.nil?

    if highest.present?
      self.update_column(:portion_marking, highest)

      if Setting.CLASSIFICATION
        short_cache = self.qname_cache
        short_cache = short_cache[4..short_cache.length] if short_cache[0..3].include?("(")
        self.update_column(:qname_cache, "(" + highest + ") " + short_cache)
      end

      self.reload
    end
  end
  
  def self.ingest(uploader, obj, options = {})
    x = Question.new
    HumanReview.adjust(obj, uploader)
    x.qtype = obj.qtype if obj.respond_to?(:qtype)
    x.qclass = obj.qclass if obj.respond_to?(:qclass)

    # non ais attributes
    x.read_only = uploader.read_only
    x
  end

  def uri_cybox_object_ids=(cybox_object_ids)
    self.uri_ids = Uri.where(cybox_object_id: cybox_object_ids).pluck(:id)
  end

  def duplication_needed?
    cybox_object_id && cybox_object_id.include?(Setting.READ_ONLY_EXT)
  end

  def set_cybox_hash
    write_attribute(:cybox_hash, CyboxHash.generate(self.guid))
  end

  def repl_params
    {
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
    if self.uris.present?
      cache_value = self.uris.collect do |x| x.display_name end.to_sentence
      if cache_value.length > 255
        self.qname_cache = cache_value[0..251] + "..."
      else
        self.qname_cache = cache_value
      end
    else
      self.qname_cache = ""
    end
  end

  private

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    time :created_at, stored: false
    text :qclass
    text :qtype
    text :qname_cache
    text :guid, as: :text_exact
    string :qclass
    string :qtype
    string :qname_cache
    string :portion_marking, stored: false
  end
end
