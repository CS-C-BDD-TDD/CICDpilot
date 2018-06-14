class AcsSetStixMarkingsToGuid < ActiveRecord::Migration
  class MStixMarking < ActiveRecord::Base; self.table_name = :stix_markings; end

  def up
    MStixMarking.class_eval do
      belongs_to :remote_object,
                 primary_key: :stix_id,
                 foreign_key: :remote_object_id,
                 foreign_type: :remote_object_type,
                 polymorphic: true
    end

    MStixMarking.all.find_in_batches do |group|
      group.each do |sm|
        if sm.remote_object_type == "AcsSet"
          if sm.remote_object != nil
            id = sm.remote_object.guid
            sm.update_columns({remote_object_id: id})
          end
        end
      end
    end
  end

  def down
    MStixMarking.class_eval do
      belongs_to :remote_object,
                 primary_key: :guid,
                 foreign_key: :remote_object_id,
                 foreign_type: :remote_object_type,
                 polymorphic: true
    end

    MStixMarking.all.find_in_batches do |group|
      group.each do |sm|
        if sm.remote_object_type == "AcsSet"
          if sm.remote_object != nil
            id = sm.remote_object.stix_id
            sm.update_columns({remote_object_id: id})
          end
        end
      end
    end
  end

end
