class Organization < ActiveRecord::Base
  validates_presence_of :short_name, :long_name
  validates_uniqueness_of :short_name
  validates_uniqueness_of :long_name
  has_many :users, primary_key: :guid, foreign_key: :organization_guid
  has_many :weather_map_images, -> { order 'created_at desc' },
    foreign_key: :organization_token, 
    primary_key: :organization_token
  has_many :acs_sets_organizations, primary_key: :guid
  has_many :acs_sets, through: :acs_sets_organizations

  # The include Auditable MUST go after the has_many audits and has_many audit_indicators
  include Auditable
  include Guidable
  include Notable
  include Serialized
  include Transferable
end
