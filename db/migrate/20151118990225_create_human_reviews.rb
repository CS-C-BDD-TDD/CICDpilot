# FYI: Legal values for status are: N - Not Reviewed, A - Approved, and
# R - Rejected. The status values will be enforced by the HumanReview model.

class CreateHumanReviews < ActiveRecord::Migration
  class MPermission < ActiveRecord::Base;self.table_name = :permissions;end

  def change
    create_table :human_reviews do |t|
      t.datetime :decided_at
      t.string  :decided_by
      t.string   :status, :limit => 1, :default => 'N', :null => false
      t.integer  :uploaded_file_id
      t.timestamps null: false
    end

    yml = YAML.load_file('config/permissions.yml')
    (yml[Rails.env]||[]).each do |name,attributes|
      if MPermission.find_by_name(name)
        puts "Permission: #{name} already exists."
        next
      end

      MPermission.create(name:name,
                         display_name: attributes['display_name'],
                         description: attributes['description'])
      puts "Permission: #{name} created."
    end
  end
end
