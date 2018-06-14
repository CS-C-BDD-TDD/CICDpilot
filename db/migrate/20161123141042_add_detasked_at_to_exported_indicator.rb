class AddDetaskedAtToExportedIndicator < ActiveRecord::Migration
  def change
		add_column :exported_indicators, :detasked_at, :datetime
		add_column :audit_logs, :audit_subtype, :string
		add_column :exported_indicators, :updated_at, :datetime
		add_column :exported_indicators,:status,:string
  end
end
