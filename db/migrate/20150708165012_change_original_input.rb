class ChangeOriginalInput < ActiveRecord::Migration
  class XOriginalInput < ActiveRecord::Base
    self.table_name = 'original_input'
  end

  def up
    add_column :original_input, :input_category, :string
    rename_column :original_input, :is_attachment, :old_is_attachment
    populate_input_category
  end

  def down
    remove_column :original_input, :input_category
    rename_column :original_input, :old_is_attachment, :is_attachment
  end

  def populate_input_category
    XOriginalInput.update_all(:input_category => 'Upload')
  end
end
