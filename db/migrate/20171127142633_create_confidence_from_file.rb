class CreateConfidenceFromFile < ActiveRecord::Migration
  def up
    if ActiveRecord::Base.connection.column_exists?(:stix_confidences, :from_file)
      remove_column :stix_confidences, :from_file
      add_column :stix_confidences, :from_file, :boolean, :default => false
    else
      add_column :stix_confidences, :from_file, :boolean, :default => false
    end
  end

  def down
    if ActiveRecord::Base.connection.column_exists?(:stix_confidences, :from_file)
      remove_column :stix_confidences, :from_file
    end
  end
end
