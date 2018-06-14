class IndicatorsCourseOfAction < ActiveRecord::Base

  self.table_name = 'indicators_course_of_actions'
  belongs_to :course_of_action, primary_key: :stix_id, foreign_key: :course_of_action_id, touch: true
  belongs_to :indicator, primary_key: :stix_id, foreign_key: :stix_indicator_id, touch: true
  belongs_to :user, foreign_key: :user_guid, primary_key: :guid

  alias_attribute :obj, :course_of_action
  alias_attribute :parent, :indicator

  include Guidable
  include Ingestible
  include LinkingTableCommon
  include Transferable

  attr_reader :is_upload

  def self.ingest(uploader, coa, parent = nil)
    x = IndicatorsCourseOfAction.new
    x.course_of_action_id = coa
    x.stix_indicator_id = parent.stix_id unless parent.nil?
    x
  end

  def is_upload
    if @is_upload.nil?
      false
    else
      @is_upload
    end
  end
  
end
