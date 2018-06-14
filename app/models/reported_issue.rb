class ReportedIssue < ActiveRecord::Base
  include Auditable
  attr_accessor :guid

  validates_presence_of :subject, message: 'must contain a subject'
  validates_presence_of :description, message: 'must contain a description'

  before_create :insert_user

  def insert_user
    if User.current_user
      self.user_guid = User.current_user.guid
    end
  end
end
