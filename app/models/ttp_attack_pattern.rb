class TtpAttackPattern < ActiveRecord::Base

  belongs_to :ttp, primary_key: :stix_id, foreign_key: :stix_ttp_id, touch: true
  belongs_to :attack_pattern, primary_key: :stix_id, foreign_key: :stix_attack_pattern_id, touch: true
  belongs_to :user, foreign_key: :user_guid, primary_key: :guid

  alias_attribute :obj, :attack_pattern
  alias_attribute :parent, :ttp

  include Guidable
  include Ingestible
  include LinkingTableCommon
  include Transferable

  attr_reader :is_upload

  def self.ingest(uploader, ap, parent = nil)
    x = TtpAttackPattern.new
    x.stix_attack_pattern_id = ap.stix_id
    x.stix_ttp_id = parent.stix_id unless parent.nil?
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
