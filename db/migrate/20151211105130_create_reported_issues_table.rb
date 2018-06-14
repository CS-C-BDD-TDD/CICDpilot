class CreateReportedIssuesTable < ActiveRecord::Migration
  def up
    create_table :reported_issues do |t|
      t.string  :subject
      t.string  :description
      t.string  :user_guid
      t.timestamps null: false
    end
  end
end
