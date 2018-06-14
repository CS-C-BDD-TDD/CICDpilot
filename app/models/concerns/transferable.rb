module Transferable extend ActiveSupport::Concern
  # This is a dummy concern, include it in models that neeed
  # to be transferred to the high side
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def updated_at_field
      "updated_at"
    end
  end
end
