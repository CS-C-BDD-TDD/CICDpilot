class RemoveNilRelatedIndicatorRecords< ActiveRecord::Migration
  def change
    Relationship.where("remote_dest_object_type='Indicator'").where("remote_src_object_type='Indicator'").find_in_batches.with_index do |rels,batch|
      puts "Processing group ##{batch}" 
      rels.each do |r|
        if Indicator.find_by_guid(r.remote_dest_object_guid)==nil || Indicator.find_by_guid(r.remote_src_object_guid)==nil
          r.delete
        end
      end
    end
  end
end
