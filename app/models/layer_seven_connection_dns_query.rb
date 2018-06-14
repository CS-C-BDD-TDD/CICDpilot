class LayerSevenConnectionDnsQuery < ActiveRecord::Base

  self.table_name = 'lsc_dns_queries'
  belongs_to :layer_seven_connection, primary_key: :guid, foreign_key: :layer_seven_connection_id, touch: true
  belongs_to :dns_query, primary_key: :cybox_object_id, foreign_key: :dns_query_id, touch: true
  belongs_to :user, foreign_key: :user_guid, primary_key: :guid

  alias_attribute :obj, :dns_query
  alias_attribute :parent, :layer_seven_connection

  include Guidable
  include Ingestible
  include LinkingTableCommon
  include Transferable

  attr_reader :is_upload

  def self.ingest(uploader, obj, parent = nil)
    x = LayerSevenConnectionDnsQuery.new
    x.dns_query_id = obj.cybox_object_id
    x.layer_seven_connection_id = parent.guid unless parent.nil?
    x
  end

  def is_upload
    if @is_upload.nil?
      false
    else
      @is_upload
    end
  end

end
