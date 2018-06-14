class ChangeControlledStructureToText < ActiveRecord::Migration
  def up
    add_column :stix_markings, :mcontrolled_structure, :text

    StixMarking.find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch}"
      group.each do |cs|
        next unless cs.mcontrolled_structure.blank?
        cs.mcontrolled_structure = cs.controlled_structure
        cs.save
      end
    end

    remove_column :stix_markings, :controlled_structure
    rename_column :stix_markings, :mcontrolled_structure, :controlled_structure
  end

  def down
    add_column :stix_markings, :mcontrolled_structure, :string

    StixMarking.find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch}"
      group.each do |cs|
        next unless cs.mcontrolled_structure.blank?
        cs.mcontrolled_structure = cs.controlled_structure
        begin
          cs.save!
        rescue Exception => e
          puts "Could not transition #{cs.id}, dropping controlled_structure"
          cs.mcontrolled_structure = ""
          cs.save
        end
      end
    end

    remove_column :stix_markings, :controlled_structure
    rename_column :stix_markings, :mcontrolled_structure, :controlled_structure
  end
end
