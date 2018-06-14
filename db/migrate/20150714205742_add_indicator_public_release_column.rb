class AddIndicatorPublicReleaseColumn < ActiveRecord::Migration
  class MStixMarking < ActiveRecord::Base
    self.table_name = :stix_markings
    has_many :isa_marking_structures, primary_key: :guid,class_name: 'MIsaMarkingStructure', foreign_key: :stix_marking_guid
  end

  class MIsaMarkingStructure < ActiveRecord::Base; self.table_name = :isa_marking_structures; end;

  class MIndicator < ActiveRecord::Base
    self.table_name = :stix_indicators

    has_many :stix_markings, ->{where(remote_object_type: 'Indicator')},primary_key: :stix_id, foreign_key: :remote_object_id, class_name: 'MStixMarking'
    has_many :isa_marking_structures, primary_key: :stix_id, class_name: 'MIsaMarkingStructure', through: :stix_markings
  end

  def up
    add_column :stix_indicators, :public_release, :boolean, default: false
    set_non_assertion_stix_marking_pr
    populate_public_release
  end

  def down
    remove_column :stix_indicators, :public_release
  end

  def set_non_assertion_stix_marking_pr
    MStixMarking.where(marking_model_type: 'ISAMarkingsType').each do |stix_marking|
      stix_marking.isa_marking_structures.each do |isa|
        isa.public_release = false
        isa.save!
      end
    end
  end

  def populate_public_release
    MIndicator.joins(:isa_marking_structures).
        where("isa_marking_structures.public_release = ? OR isa_marking_structures.cs_orgs like ?",true,"%USA.USG%").
        each do |indicator|

      indicator.public_release = true
      indicator.save!
    end
  end
end
