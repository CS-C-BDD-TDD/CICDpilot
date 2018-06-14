class HumanReviewField < ActiveRecord::Base
  belongs_to :human_review, counter_cache: true

  scope :completed, -> {where("object_field_revised is not null")}
  scope :pending, -> {where("object_field_revised is null")}

  default_scope ->{order(id: :asc)}

  validates_presence_of :object_id,:object_type,:object_field,:object_field_original,:object_sha2
  validates_presence_of :human_review, message: 'Must be a part of a Human Review File'

  after_save :update_hr_completed_count

  def object_field_revised=(newval)
    write_attribute(:object_field_revised,newval)
    if !self.object_field_revised || self.object_field_revised == self.object_field_original
      write_attribute(:is_changed,false)
    else
      write_attribute(:is_changed,true)
    end
  end

  private

  def update_hr_completed_count
    changed_object_field = self.changes['object_field_revised']
    human_review = self.human_review.reload
    return if human_review.status == 'A'
    return unless changed_object_field
    if changed_object_field.first.blank? && changed_object_field.second.present?
      human_review.update(comp_human_review_fields_count: self.human_review.comp_human_review_fields_count + 1)
    elsif changed_object_field.second.blank? && changed_object_field.first.present?
      human_review.update(comp_human_review_fields_count: self.human_review.comp_human_review_fields_count - 1)
    end
  end
end
