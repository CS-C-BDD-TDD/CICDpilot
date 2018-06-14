class SocketAddressAddress < ActiveRecord::Base

  self.table_name = 'socket_address_addresses'
  belongs_to :address, primary_key: :cybox_object_id, foreign_key: :address_id, touch: true
  belongs_to :socket_address, primary_key: :cybox_object_id, foreign_key: :socket_address_id, touch: true
  belongs_to :user, foreign_key: :user_guid, primary_key: :guid

  alias_attribute :obj, :address
  alias_attribute :parent, :socket_address

  include Guidable
  include Ingestible
  include LinkingTableCommon
  include Transferable

  attr_reader :is_upload

  def self.ingest(uploader, obj, parent = nil)
    x = SocketAddressAddress.new
    x.address_id = obj.cybox_object_id
    x.socket_address_id = parent.cybox_object_id unless parent.nil?
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
