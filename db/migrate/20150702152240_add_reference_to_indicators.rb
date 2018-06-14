class AddReferenceToIndicators < ActiveRecord::Migration
  def change
  	add_column :stix_indicators, :reference, :string
  end
end
