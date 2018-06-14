class NetworkConnectionLayerSevenConnection < ActiveRecord::Base

  self.table_name = 'nc_layer_seven_connections'
  belongs_to :layer_seven_connection, primary_key: :guid, foreign_key: :layer_seven_connection_id, touch: true
  belongs_to :network_connection, primary_key: :cybox_object_id, foreign_key: :network_connection_id, touch: true
  belongs_to :user, foreign_key: :user_guid, primary_key: :guid

  alias_attribute :obj, :layer_seven_connection
  alias_attribute :parent, :network_connection

  include Guidable
  include Ingestible
  include LinkingTableCommon
  include Transferable

  attr_reader :is_upload

  def self.ingest(uploader, obj, parent = nil)
    x = NetworkConnectionLayerSevenConnection.new
    x.layer_seven_connection_id = obj.guid
    x.network_connection_id = parent.cybox_object_id unless parent.nil?
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
