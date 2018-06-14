class AddAcs21Columns < ActiveRecord::Migration
  def change
    create_table :further_sharings do |t|
      t.string :scope, null: false
      t.string :effect, null: false
      t.string :isa_assertion_structure_guid
      t.string :guid
    end

    add_column :isa_assertion_structures, :cs_info_caveat, :string
    add_column :isa_assertion_structures, :sharing_default, :string
  end
end
