class AcsSetsOrganization < ActiveRecord::Base
  include Guidable
  include Transferable

  belongs_to :acs_set, primary_key: :guid
  belongs_to :organization, primary_key: :guid
end
