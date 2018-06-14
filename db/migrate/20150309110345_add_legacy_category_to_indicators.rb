class AddLegacyCategoryToIndicators < ActiveRecord::Migration
  def change
    add_column :stix_indicators, :legacy_category, :string
    add_column :stix_packages, :legacy_category, :string
  end
end
