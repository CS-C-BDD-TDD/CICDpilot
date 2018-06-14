class AddShortDescriptionNormalizedToStixPackages < ActiveRecord::Migration
  def change
    if !ActiveRecord::Base.connection.column_exists?(:stix_packages, :short_description_normalized)
      add_column :stix_packages, :short_description_normalized, :string, linit: 255
      add_index :stix_packages, :short_description_normalized
    end
    
    reversible do |dir|
      dir.up do
        # Populate the new column with data
        execute "UPDATE STIX_PACKAGES SET SHORT_DESCRIPTION_NORMALIZED = SUBSTR(LOWER(SHORT_DESCRIPTION), 1, 255)"
      end
      # No Down is needed, dropping the column is enough
    end
 
  end
end
