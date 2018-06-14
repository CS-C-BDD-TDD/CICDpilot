class DnsQueryResourceRecord < ActiveRecord::Base

  self.table_name = 'dns_query_resource_records'
  belongs_to :resource_record, primary_key: :guid, foreign_key: :resource_record_id, touch: true
  belongs_to :dns_query, primary_key: :cybox_object_id, foreign_key: :dns_query_id, touch: true
  belongs_to :user, foreign_key: :user_guid, primary_key: :guid

  alias_attribute :obj, :resource_record
  alias_attribute :parent, :dns_query

  include Guidable
  include Ingestible
  include LinkingTableCommon
  include Transferable

  attr_reader :is_upload

  def self.ingest(uploader, obj, parent = nil)
    x = DnsQueryResourceRecord.new
    x.resource_record_id = obj.guid
    x.dns_query_id = parent.cybox_object_id unless parent.nil?
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
