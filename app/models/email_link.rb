class EmailLink < ActiveRecord::Base
  include Guidable
  include Transferable

  belongs_to :link, primary_key: :guid
  belongs_to :email_message, primary_key: :guid
end
