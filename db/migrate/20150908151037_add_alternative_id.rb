class AddAlternativeId < ActiveRecord::Migration
  def change
    add_column :stix_indicators, :alternative_id, :string
  end
end
