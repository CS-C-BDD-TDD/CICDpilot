class EmailUri < ActiveRecord::Base
  include Guidable
  include Transferable

  belongs_to :uri, primary_key: :guid
  belongs_to :email_message, primary_key: :guid
end
