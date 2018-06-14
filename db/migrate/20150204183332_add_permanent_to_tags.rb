class AddPermanentToTags < ActiveRecord::Migration

  class MigrationPermaTag < ActiveRecord::Base; self.table_name = 'tags'; end

  def change
    add_column :tags, :is_permanent, :boolean, default: false
    MigrationPermaTag.reset_column_information
    export_to_ecs_tag = MigrationPermaTag.find_by_name_normalized('exported-to-ecs')||
                        MigrationPermaTag.new()
    excluded_from_e1_tag = MigrationPermaTag.find_by_name_normalized("excluded-from-e1")||
                        MigrationPermaTag.new()
    export_to_ecs_tag.name = 'exported-to-ecs'
    export_to_ecs_tag.name_normalized = 'exported-to-ecs'
    export_to_ecs_tag.is_permanent = true
    export_to_ecs_tag.guid = "9fa676fe-9a85-4154-990f-ec058646d555"
    excluded_from_e1_tag.name = 'excluded-from-e1'
    excluded_from_e1_tag.name_normalized = 'excluded-from-e1'
    excluded_from_e1_tag.is_permanent = true
    excluded_from_e1_tag.guid = "7e43e31b-5905-470e-b938-7dbbbe06b522"
    export_to_ecs_tag.save
    excluded_from_e1_tag.save
  end
end
