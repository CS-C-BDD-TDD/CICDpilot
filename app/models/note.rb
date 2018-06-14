class Note < ActiveRecord::Base
  belongs_to :user, primary_key: :guid, foreign_key: :user_guid
  validates_presence_of :user
  belongs_to :target, primary_key: :guid, foreign_key: :target_guid, polymorphic: true, foreign_type: :target_class
  validates_presence_of :target
  validates_presence_of :note
  include Guidable
  include Serialized
  include Transferable
end
