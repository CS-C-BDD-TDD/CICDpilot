class AddReceivedFromSystemGuidToIndicators < ActiveRecord::Migration
  def change
    add_column :stix_indicators, :received_from_system_guid,:string
  end
end
