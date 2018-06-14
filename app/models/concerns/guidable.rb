module Guidable extend ActiveSupport::Concern
  included do |base|
    validates_presence_of :guid
    before_validation :set_guid
    def set_guid
      if self.guid.blank?
        self.guid = SecureRandom.uuid
      end
    end
    before_validation :set_created_by_guids, on: :create
    def set_created_by_guids
      return unless User.current_user
      self.created_by_user_guid = User.current_user.guid if self.has_attribute?(:created_by_user_guid) && !self.changes["created_by_user_guid"]
      return unless User.current_user.organization
      self.created_by_organization_guid = User.current_user.organization.guid if self.has_attribute?(:created_by_organization_guid) && !self.changes["created_by_organization_guid"]
    end
    before_validation :set_updated_by_guids
    def set_updated_by_guids
      return unless User.current_user
      self.updated_by_user_guid = User.current_user.guid if self.has_attribute?(:updated_by_user_guid) && !self.changes["updated_by_user_guid"]
      return unless User.current_user.organization
      self.updated_by_organization_guid = User.current_user.organization.guid if self.has_attribute?(:updated_by_organization_guid) && !self.changes["updated_by_organization_guid"]
    end
  end

  module ClassMethods
  end
end
