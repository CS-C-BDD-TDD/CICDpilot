class Password < ActiveRecord::Base
  PASSWORD_STORAGE_LIMIT = 10
  MAXIMUM_LIFESPAN = 180
  MINIMUM_LIFESPAN = 1

  belongs_to :user, primary_key: :guid, foreign_key: :user_guid

  default_scope {order(created_at: :desc)}

  def expired?
    return false if Setting.SSO_AD
    self.requires_change || self.created_at < MAXIMUM_LIFESPAN.days.ago
  end

  def incubated?
    return false if Setting.SSO_AD
    self.created_at > MINIMUM_LIFESPAN.days.ago && !self.requires_change
  end
end