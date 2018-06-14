class QuestionUri < ActiveRecord::Base

  self.table_name = 'question_uris'
  belongs_to :uri, primary_key: :cybox_object_id, foreign_key: :uri_id, touch: true
  belongs_to :question, primary_key: :guid, foreign_key: :question_id, touch: true
  belongs_to :user, foreign_key: :user_guid, primary_key: :guid

  alias_attribute :obj, :uri
  alias_attribute :parent, :question

  include Guidable
  include Ingestible
  include LinkingTableCommon
  include Transferable

  attr_reader :is_upload

  def self.ingest(uploader, obj, parent = nil)
    x = QuestionUri.new
    x.uri_id = obj.cybox_object_id
    x.question_id = parent.guid unless parent.nil?
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
