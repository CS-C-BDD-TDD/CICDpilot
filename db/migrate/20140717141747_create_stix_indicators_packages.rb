class CreateStixIndicatorsPackages < ActiveRecord::Migration
  def change
    create_table :stix_indicators_packages do |t|
      t.string :stix_package_id
      t.string :stix_indicator_id
      t.timestamps
    end

    add_index :stix_indicators_packages, :stix_package_id
    add_index :stix_indicators_packages, :stix_indicator_id
  end
end
