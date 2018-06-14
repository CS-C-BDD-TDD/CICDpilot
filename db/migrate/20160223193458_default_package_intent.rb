class DefaultPackageIntent < ActiveRecord::Migration
  def change
    change_column :stix_packages, :package_intent, :string, default: 'Indicators'
  end
end
