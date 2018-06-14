class UploadedFileMappingToSanitizedId < ActiveRecord::Migration
  class MOriginalInput < ActiveRecord::Base
    self.table_name = :original_input
  end
  class MCiapIdMapping < ActiveRecord::Base
    self.table_name = :id_mappings
  end
  class MOriginalInputCiapIdMapping < ActiveRecord::Base
    self.table_name = :original_input_id_mappings
  end

  XML_SANITIZED = 'Sanitized'
  XML_UNICORN = 'Transfer'

  def up
    if !ActiveRecord::Base.connection.table_exists?(:original_input_id_mappings)
      create_table :original_input_id_mappings do |t|
        t.integer :original_input_id
        t.integer :ciap_id_mapping_id
      end
    end

    total_id_mappings = MCiapIdMapping.count
    if total_id_mappings>0
      total = MOriginalInput.count
      current=0
      MOriginalInput.find_in_batches(batch_size: 100).with_index do |group,batch|
        start=batch*100+1
        stop=batch*100+100
        if (stop>total)
          stop=total
        end
        puts "Migrating #{start}-#{stop} original_input records out of #{total}"
        group.each do |input|
          if input.input_category == 'Upload' and (input.input_sub_category == XML_SANITIZED or input.input_sub_category == XML_UNICORN)
            id=Hash.from_xml(input.raw_content)
            id_mapping=MCiapIdMapping.find_by_after_id(id['STIX_Package']['id'])
            if id_mapping
              MOriginalInputCiapIdMapping.create!(:original_input_id => input.id,:ciap_id_mapping_id => id_mapping.id)
            end
          end
        end
      end
      puts "Migrated #{total} original_input records out of #{total}"
    end
  end

  def down
    drop_table :original_input_id_mappings
  end
end
