class AddTagTypeToTagAssignments < ActiveRecord::Migration
  def change
    add_column :tag_assignments, :tag_type, :string
  end
end
