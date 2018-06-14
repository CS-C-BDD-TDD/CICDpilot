class ResourceRecord < ActiveRecord::Base

  self.table_name = "resource_records"

  include Auditable
  include Guidable
  include Ingestible
  include AcsDefault
  include Serialized
  include Transferable

  has_many :dns_query_resource_records, primary_key: :guid, foreign_key: :resource_record_id, dependent: :destroy
  has_many :dns_queries, through: :dns_query_resource_records

  has_many :resource_record_dns_records, primary_key: :guid, foreign_key: :resource_record_id, dependent: :destroy
  has_many :dns_records, through: :resource_record_dns_records, before_remove: :audit_obj_removal

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  before_save :set_object_caches
  after_save :set_portion_marking

  validates_presence_of :record_type

  ResourceRecordTypes = [
    {value: "answer", name: "Answer Resource Record"},
    {value: "authority", name: "Authority Resource Record"},
    {value: "additional", name: "Additional Record"}
  ]

  def stix_packages
    packages = []

    packages |= self.dns_queries.collect(&:stix_packages).flatten if self.dns_queries.present?

    packages
  end
  
# Trickles down the disseminated feed value to all of the associated objects
def trickledown_feed
  begin
    associations = ["dns_records"]
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

    markings = self.dns_records.collect(&:portion_marking)

    highest = Classification.determine_highest_single(markings) unless markings.nil?

    if highest.present?
      self.update_column(:portion_marking, highest)
      
      if Setting.CLASSIFICATION
        short_cache = self.dns_record_cache
        short_cache = short_cache[4..short_cache.length] if short_cache[0..3].include?("(")
        self.update_column(:dns_record_cache, "(" + highest + ") " + short_cache)
      end

      self.reload
    end
  end

  def self.ingest(uploader, obj, options = {})
    x = ResourceRecord.new
    HumanReview.adjust(obj, uploader)

    # non ais attributes
    x.read_only = uploader.read_only
    x
  end

  def dns_record_cybox_object_ids=(cybox_object_ids)
    self.dns_record_ids = DnsRecord.where(cybox_object_id: cybox_object_ids).pluck(:id)
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

  def set_object_caches
    if self.dns_records.present?
      cache_value = self.dns_records.collect do |x| x.display_name end.to_sentence

      if cache_value.length > 255
        self.dns_record_cache = cache_value[0..251] + "..."
      else
        self.dns_record_cache = cache_value
      end
    else
      self.dns_record_cache = ""
    end
  end

  private

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    time :created_at, stored: false
    text :record_type
    text :dns_record_cache
    string :dns_record_cache
    string :record_type
    text :guid, as: :text_exact
  end
end
