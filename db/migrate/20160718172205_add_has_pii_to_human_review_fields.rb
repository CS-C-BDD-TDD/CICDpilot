class AddHasPiiToHumanReviewFields < ActiveRecord::Migration
  def change
  	add_column :human_review_fields, :has_pii, :boolean
  end
end
