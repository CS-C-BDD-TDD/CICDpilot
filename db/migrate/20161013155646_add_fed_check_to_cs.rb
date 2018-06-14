class AddFedCheckToCs < ActiveRecord::Migration
  ##NOTE
  # We should not be concerned with populating existing data for this column
  # This column is to support a new requirement for AIS handling
  # It is not needed for existing data to support the AIS feeds or anything else

  def change
    add_column :contributing_sources,:is_federal,:boolean
  end
end