# NOTE: Should be included in classes AFTER Guidable.

module Cyboxable extend ActiveSupport::Concern

  included do |base|
    include ClassifiedObject
    has_many :stix_markings, primary_key: :guid, as: :remote_object, dependent: :destroy
    has_many :isa_marking_structures, primary_key: :cybox_object_id, through: :stix_markings, dependent: :destroy
    has_many :isa_assertion_structures, primary_key: :cybox_object_id, through: :stix_markings, dependent: :destroy

    CLASSIFICATION_CONTAINED_BY = [:indicators] unless const_defined?("CLASSIFICATION_CONTAINED_BY")

    accepts_nested_attributes_for :stix_markings, allow_destroy: true , reject_if: :update_markings
    before_save :set_cybox_object_id
    before_save :set_obj_controlled_structures

    def update_markings(attributes)
      return true if attributes.blank?
      return false if self.new_record?
      marking = StixMarking.find_by_stix_id(attributes[:stix_id])
      return false unless marking
      if marking.isa_marking_structures.present? && attributes[:isa_marking_structures_attributes].present?
        attributes[:isa_marking_structures_attributes].each do |attr|
          isa = marking.isa_marking_structures.select {|i| i.stix_id == attr[:stix_id]}.first
          attr.merge!(id: isa.id)
        end
      end
      false
    end

    def set_cybox_object_id
      if self.cybox_object_id.blank?
        self.cybox_object_id = SecureRandom.cybox_object_id(self)
      end
      if self.respond_to?(:set_cybox_hash)
        self.set_cybox_hash
      elsif self.respond_to?(:cybox_hash) && self.cybox_hash.blank?
        errors.add(:cybox_hash, "Unable to populate Cybox Hash on the #{self.class.to_s}")
      end
    end

    def set_obj_controlled_structures
      if self.respond_to?(:set_controlled_structures)
        self.set_controlled_structures
      end
    end

    def display_class_name
			self.class.to_s
    end
  end

  module ClassMethods
  end
end
