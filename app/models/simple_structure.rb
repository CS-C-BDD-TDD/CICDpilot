class SimpleStructure < ActiveRecord::Base
  belongs_to :stix_marking, primary_key: :stix_id, foreign_key: :stix_marking_id

  include Auditable
  include Guidable
  include Stixable
  include Transferable

  def self.ingest(uploader, marking, msobj)
    s = SimpleStructure.new
    s.stix_marking_id = marking.stix_id
    s.set_guid
    s.stix_id = msobj.stix_id
    s.set_stix_id
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      s.stix_id = s.stix_id + Setting.READ_ONLY_EXT
      s.guid = s.guid + Setting.READ_ONLY_EXT
    end

    s.statement = msobj.statement

    s
  end

end
