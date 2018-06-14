class TtpPackage < ActiveRecord::Base

  belongs_to :ttp, primary_key: :stix_id, foreign_key: :stix_ttp_id, touch: true
  belongs_to :stix_package, primary_key: :stix_id, foreign_key: :stix_package_id, touch: true
  belongs_to :user, foreign_key: :user_guid, primary_key: :guid

  alias_attribute :obj, :ttp
  alias_attribute :parent, :stix_package

  include Guidable
  include Ingestible
  include LinkingTableCommon
  include Transferable

  attr_reader :is_upload

  def self.ingest(uploader, tpack, parent = nil)
    x = TtpPackage.new
    x.stix_ttp_id = tpack.stix_id
    x.stix_package_id = parent.stix_id unless parent.nil?
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
