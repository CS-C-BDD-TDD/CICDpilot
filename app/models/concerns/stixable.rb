# NOTE: Should be included in classes AFTER Guidable.

module Stixable extend ActiveSupport::Concern
  included do |base|
    validates_presence_of :stix_id
    before_validation :set_stix_id
    def set_stix_id
      if self.stix_id.blank?
        self.stix_id = SecureRandom.stix_id(self)
      end
    end
  end

  module ClassMethods
  end
end
