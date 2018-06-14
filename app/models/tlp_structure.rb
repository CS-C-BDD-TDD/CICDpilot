class TlpStructure < ActiveRecord::Base
  belongs_to :stix_marking, primary_key: :stix_id, foreign_key: :stix_marking_id

  COLORS = ["white","green","amber","red","black"]

  include Auditable
  include Guidable
  include Stixable
  include Transferable

  def self.ingest(uploader, marking, msobj)
    s = TlpStructure.new
    s.stix_marking_id = marking.stix_id
    s.set_guid
    s.stix_id = msobj.stix_id
    s.set_stix_id
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      s.stix_id = s.stix_id + Setting.READ_ONLY_EXT
      s.guid = s.guid + Setting.READ_ONLY_EXT
    end

    s.color = msobj.color.downcase

    s
  end

  def self.most_restrictive(colors)
    most_restrictive = nil
    most_restrictive_index = nil
    colors.each do |color|
      color_index = TlpStructure::COLORS.index(color)
      if most_restrictive.blank?
        most_restrictive = color
        most_restrictive_index = color_index
      elsif color_index > most_restrictive_index
        most_restrictive = color
        most_restrictive_index = color_index
      end
    end
    most_restrictive
  end
  
end
