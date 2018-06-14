class FixMarkingStructures < ActiveRecord::Migration

  # The class for the top-level STIXMarking record

  class XStixMarking < ActiveRecord::Base
    self.table_name = 'stix_markings'
  end

  # The class for the new ACS 2.0 ISA Marking Structures

  class XIsaMarkingStructure < ActiveRecord::Base
    self.table_name = 'isa_marking_structures'
    belongs_to :x_stix_marking, primary_key: :guid, foreign_key: :stix_marking_guid
  end

  def up
    lst = XIsaMarkingStructure.where('marking_model_type IS NULL').all
    lst.each do |x|
      m = x.x_stix_marking
      unless m.nil?
        x.marking_model_type = m.marking_model_type
        x.save
      end
    end
  end

end
