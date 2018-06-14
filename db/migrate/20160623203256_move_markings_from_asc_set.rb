class MoveMarkingsFromAscSet < ActiveRecord::Migration
  class MIsaMarkingStructure < ActiveRecord::Base
    self.table_name = :isa_marking_structures
    belongs_to :stix_marking, primary_key: :stix_id, foreign_key: :stix_marking_id, class_name: 'MStixMarking'

    include Stixable
    include Guidable
  end
  class MTlpMarkingStructure < ActiveRecord::Base
    self.table_name = :tlp_structures
    belongs_to :stix_marking, primary_key: :stix_id, foreign_key: :stix_marking_id, class_name: 'MStixMarking'

    include Stixable
    include Guidable
  end
  class MStixMarking < ActiveRecord::Base
    self.table_name = :stix_markings

    has_one :isa_marking_structure, class_name: 'MIsaMarkingStructure', primary_key: :stix_id, foreign_key: :stix_marking_id
    has_one :tlp_marking_structure, class_name: 'MTlpMarkingStructure', primary_key: :stix_id, foreign_key: :stix_marking_id

    include Stixable
    include Guidable
  end
  class MAcsSet < ActiveRecord::Base
    self.table_name = :acs_sets

    has_many :stix_markings, class_name: 'MStixMarking', primary_key: :stix_id, foreign_key: :remote_object_id, foreign_type: 'AcsSet'
    has_many :indicators, foreign_key: :acs_set_id
    has_many :stix_packages, foreign_key: :acs_set_id
  end

  def up
    MAcsSet.all.each do |set|
      set.stix_markings.each do |sm|
        set.indicators.find_in_batches do |group|
          group.each {|i| migrate_marking(sm,i)}
        end
        set.stix_packages.find_in_batches do |group|
          group.each {|p| migrate_marking(sm,p)}
        end
        sm.isa_marking_structure.destroy!
        sm.tlp_marking_structure.destroy! if sm.tlp_marking_structure.present?
      end
    end
  end

  def down
    puts "Cannot roll back this migration"
  end

  def migrate_marking(marking,object)
    isa = marking.isa_marking_structure
    tlp = marking.tlp_marking_structure

    new_sm = dup_obj marking
    new_isa = dup_obj isa
    new_tlp = dup_obj tlp if tlp.present?

    new_sm.isa_marking_structure = new_isa
    new_sm.tlp_marking_structure = new_tlp if tlp.present?
    new_sm.remote_object_id = object.stix_id
    new_sm.remote_object_type = object.class.to_s

    new_sm.save!
    puts "#{object.class.to_s} #{object.stix_id} has had Data Marking #{new_sm.stix_id} added to it"
  end

  def dup_obj(object)
    new_obj = object.dup
    new_obj.stix_id = ""
    new_obj.guid = ""
    new_obj.set_stix_id
    new_obj.set_guid
    new_obj
  end
end
