class AddUrlToReportedIssuesTable < ActiveRecord::Migration
  def change
    add_column :reported_issues, :called_from, :string
  end
end
