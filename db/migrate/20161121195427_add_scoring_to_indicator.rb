class AddScoringToIndicator < ActiveRecord::Migration
  def change
    add_column :stix_indicators, :timelines, :string
    add_column :stix_indicators, :source_of_report, :string
    add_column :stix_indicators, :target_of_attack, :string
    add_column :stix_indicators, :target_scope, :string
    add_column :stix_indicators, :actor_attribution, :string
    add_column :stix_indicators, :actor_type, :string
    add_column :stix_indicators, :modus_operandi, :string
  end
end
