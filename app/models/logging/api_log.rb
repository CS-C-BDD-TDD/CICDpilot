module Logging
  class ApiLog < ActiveRecord::Base
    belongs_to :user,primary_key: :guid, foreign_key: :user_guid
  end
end