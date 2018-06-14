class AddColumnToReplications < ActiveRecord::Migration
  def change
    add_column :replications, :repl_type, :string
  end
end
