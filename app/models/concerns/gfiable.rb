module Gfiable
  extend ActiveSupport::Concern
  included do |base|
    accepts_nested_attributes_for :gfi, :reject_if => :is_classification_disabled?, allow_destroy: true
  end

  def is_classification_disabled?
    return false if self.gfi.blank?
    return false if defined?(Setting.CLASSIFICATION) && Setting.CLASSIFICATION
    true
  end

  module ClassMethods
  end

end
