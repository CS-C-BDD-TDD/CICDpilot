class DnsQueryQuestion < ActiveRecord::Base

  self.table_name = 'dns_query_questions'
  belongs_to :question, primary_key: :guid, foreign_key: :question_id, touch: true
  belongs_to :dns_query, primary_key: :cybox_object_id, foreign_key: :dns_query_id, touch: true
  belongs_to :user, foreign_key: :user_guid, primary_key: :guid

  alias_attribute :obj, :question
  alias_attribute :parent, :dns_query

  include Guidable
  include Ingestible
  include LinkingTableCommon
  include Transferable

  attr_reader :is_upload

  def self.ingest(uploader, obj, parent = nil)
    x = DnsQueryQuestion.new
    x.question_id = obj.guid
    x.dns_query_id = parent.cybox_object_id unless parent.nil?
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
