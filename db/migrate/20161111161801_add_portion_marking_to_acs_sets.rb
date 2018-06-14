class AddPortionMarkingToAcsSets < ActiveRecord::Migration
  def change
  	add_column :acs_sets, :portion_marking, :string
  end
end
