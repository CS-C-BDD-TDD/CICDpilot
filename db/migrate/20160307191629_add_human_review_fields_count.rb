class AddHumanReviewFieldsCount < ActiveRecord::Migration
  class MHumanReview < ActiveRecord::Base;self.table_name = :human_reviews;end
  class MHumanReviewFields < ActiveRecord::Base;self.table_name = :human_review_fields;end

  def up
    add_column :human_reviews, :human_review_fields_count, :integer, default: 0
    add_column :human_reviews, :comp_human_review_fields_count, :integer, default: 0

    MHumanReview.reset_column_information
    MHumanReview.all.each do |human_review|
      human_review.update(human_review_fields_count: MHumanReviewFields.where(human_review_id: human_review.id).length)
      human_review.update(comp_human_review_fields_count: MHumanReviewFields.where(human_review_id: human_review.id).
          where("object_field_revised is not null").length)
    end
  end

  def down
    remove_column :human_reviews,:human_review_fields_count
    remove_column :human_reviews,:comp_human_review_fields_count
  end
end
