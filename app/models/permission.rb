class Permission < ActiveRecord::Base
  has_many :group_permissions
  has_many :groups, through: :group_permissions
  has_many :users, through: :groups

  validates_presence_of   :name, :description
  validates_uniqueness_of :name
  include Auditable
  include Guidable
  include Serialized
end
