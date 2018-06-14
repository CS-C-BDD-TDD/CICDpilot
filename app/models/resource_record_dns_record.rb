class ResourceRecordDnsRecord < ActiveRecord::Base

  self.table_name = 'resource_record_dns_records'
  belongs_to :dns_record, primary_key: :cybox_object_id, foreign_key: :dns_record_id, touch: true
  belongs_to :resource_record, primary_key: :guid, foreign_key: :resource_record_id, touch: true
  belongs_to :user, foreign_key: :user_guid, primary_key: :guid

  alias_attribute :obj, :dns_record
  alias_attribute :parent, :resource_record

  include Guidable
  include Ingestible
  include LinkingTableCommon
  include Transferable

  attr_reader :is_upload

  def self.ingest(uploader, obj, parent = nil)
    x = DnsQueryResourceRecord.new
    x.dns_record_id = obj.cybox_object_id
    x.resource_record_id = parent.guid unless parent.nil?
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
