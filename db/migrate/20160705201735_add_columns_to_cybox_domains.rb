class AddColumnsToCyboxDomains < ActiveRecord::Migration
  def change
  	add_column :cybox_domains, :iso_country_code, :string
	add_column :cybox_domains, :com_threat_score, :string
	add_column :cybox_domains, :gov_threat_score, :string
	add_column :cybox_domains, :agencies_sensors_seen_on, :string, limit: 1000
	add_column :cybox_domains, :first_date_seen_raw, :string
	add_column :cybox_domains, :first_date_seen, :datetime
	add_column :cybox_domains, :last_date_seen_raw, :string
	add_column :cybox_domains, :last_date_seen, :datetime
	add_column :cybox_domains, :combined_score, :string
	add_column :cybox_domains, :category_list, :string, :limit => 500
  end
end
