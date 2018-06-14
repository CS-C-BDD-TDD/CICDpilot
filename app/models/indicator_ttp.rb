class IndicatorTtp < ActiveRecord::Base

  belongs_to :indicator, primary_key: :stix_id, foreign_key: :stix_indicator_id, touch: true
  belongs_to :ttp, primary_key: :stix_id, foreign_key: :stix_ttp_id, touch: true

  alias_attribute :obj, :ttp
  alias_attribute :parent, :indicator

  include Guidable
  include Ingestible
  include LinkingTableCommon
  include Transferable

  attr_reader :is_upload

  def self.ingest(uploader, t, parent = nil)
    x = IndicatorTtp.new
    x.stix_ttp_id = t
    x.stix_indicator_id = parent.stix_id unless parent.nil?
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
