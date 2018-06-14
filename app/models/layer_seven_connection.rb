class LayerSevenConnection < ActiveRecord::Base

  self.table_name = "layer_seven_connections"

  include Auditable
  include Guidable
  include Ingestible
  include AcsDefault
  include Serialized
  include Transferable

  has_many :network_connection_layer_seven_connections, primary_key: :guid, foreign_key: :layer_seven_connection_id, dependent: :destroy
  has_many :network_connections, through: :network_connection_layer_seven_connections
  has_many :stix_packages, through: :network_connections

  belongs_to :http_session, class_name: 'HttpSession', primary_key: :cybox_object_id, foreign_key: :http_session_id

  has_many :layer_seven_connection_dns_queries, primary_key: :guid, foreign_key: :layer_seven_connection_id, dependent: :destroy
  has_many :dns_queries, through: :layer_seven_connection_dns_queries, before_remove: :audit_obj_removal

  before_save :set_object_caches

  def self.ingest(uploader, obj, options = {})
    x = LayerSevenConnection.new
    HumanReview.adjust(obj, uploader)

    # non ais attributes
    x.read_only = uploader.read_only
    x
  end

  def dns_query_cybox_object_ids=(cybox_object_ids)
    self.dns_query_ids = DnsQuery.where(cybox_object_id: cybox_object_ids).pluck(:id)
  end

  def duplication_needed?
    cybox_object_id && cybox_object_id.include?(Setting.READ_ONLY_EXT)
  end

  def set_cybox_hash
    write_attribute(:cybox_hash, CyboxHash.generate(self.guid))
  end

  def repl_params
    {
      guid: guid,
      dns_query_cache: dns_query_cache
    }
  end

  def set_object_caches
    if self.dns_queries.present?
      cache_value = self.dns_queries.collect do |x| x.display_name end.to_sentence

      if cache_value.length > 255
        self.dns_query_cache = cache_value[0..251] + "..."
      else
        self.dns_query_cache = cache_value
      end
    else
      self.dns_query_cache = ""
    end
  end

  private

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    time :created_at, stored: false
    time :updated_at, stored: false
    text :dns_query_cache
    string :dns_query_cache
    text :guid, as: :text_exact
    string :guid

    text :http_session_user_agent do
      http_session.present? ? http_session.user_agent : ''
    end

    text :http_session_domain_name do
      http_session.present? ? http_session.domain_name : ''
    end

    text :http_session_port do
      http_session.present? ? http_session.port : ''
    end

    text :http_session_referer, as: :http_session_referer_text_uaxm do
      http_session.present? ? http_session.referer : ''
    end
  end
end
