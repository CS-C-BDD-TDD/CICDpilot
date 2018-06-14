class EmailFile < ActiveRecord::Base
  include Guidable
  include Transferable

  belongs_to :cybox_file, primary_key: :guid
  belongs_to :email_message, primary_key: :guid
end
