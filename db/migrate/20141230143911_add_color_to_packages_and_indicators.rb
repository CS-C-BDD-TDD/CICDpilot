class AddColorToPackagesAndIndicators < ActiveRecord::Migration
  def change
    add_column :stix_packages, :legacy_color, :string
    add_column :stix_indicators, :legacy_color, :string
  end
end
