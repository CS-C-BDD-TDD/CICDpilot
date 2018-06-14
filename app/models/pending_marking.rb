class PendingMarking < ActiveRecord::Base
  belongs_to :object, polymorphic: true, primary_key: :guid, foreign_key: :remote_object_guid, foreign_type: :remote_object_type, touch: true
end
