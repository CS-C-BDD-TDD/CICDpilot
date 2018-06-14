module Notable extend ActiveSupport::Concern
  included do |base|
    has_many :notes, -> {where(target_class: base.to_s)}, foreign_key: :target_guid, primary_key: :guid
  end

  module ClassMethods
  end

end
