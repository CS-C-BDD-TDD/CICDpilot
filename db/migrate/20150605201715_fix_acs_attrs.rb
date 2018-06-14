class FixAcsAttrs < ActiveRecord::Migration

  # The class for the top-level STIXMarking record

  class YStixMarking < ActiveRecord::Base
    self.table_name = 'stix_markings'
  end

  # The class for the new ACS 2.0 ISA Marking Structures

  class YIsaMarkingStructure < ActiveRecord::Base
    self.table_name = 'isa_marking_structures'
    belongs_to :y_stix_marking, primary_key: :guid, foreign_key: :stix_marking_guid
  end

  def up
    lst = YIsaMarkingStructure.all
    lst.each do |x|
      if x.marking_model_type == 'ISAMarkingsAssertionType' ||
         x.marking_model_type == 'ISAMarkingsType'
        parent = x.y_stix_marking

        # 1. Packages marked universally should be defaults.
        if parent && parent.remote_object_type.match('Package') &&
           parent.controlled_structure = '//node()'
          x.is_default_marking = true
        end

        # 2. Indicators markings cannot be defaults. Plus, in the CIAP UI,
        # Indicator markings should apply to the Indicator plus its children.
        if parent && parent.remote_object_type.match('Indicator')
          x.is_default_marking = false
          # ISA Marking applies to Indicator and children
          parent.controlled_structure =
            "//*[@id=\"#{parent.remote_object_id}\"]/descendant-or-self::node()"
        end

        # 3. All markings in CIAP are unclassfied.
        x.cs_classification = 'U'
      end

      x.save
      parent.save unless parent.nil?
    end # Loop
  end

end
