module ClassifiedObject extend ActiveSupport::Concern
  included do |base|
    # before_validation :set_portion_marking_cache
    validate :object_level_marking
    after_save :set_portion_marking

    scope :classification_limit, ->(classification) {Setting.CLASSIFICATION && where(portion_marking: Classification.list_allowable(classification))}
    scope :classification_greater, ->(classification) {Setting.CLASSIFICATION && where(portion_marking: Classification.list_allowable_greater(classification))}

    def object_level_marking
      return unless Setting.CLASSIFICATION
      return if self.is_upload

      object_classification = self.stix_markings.select {|s| s.remote_object_field.blank? && s.isa_assertion_structure.present? && !s.isa_assertion_structure.marked_for_destruction? && !s.marked_for_destruction?}.collect(&:isa_assertion_structure).compact.first
      object_classification ||= self.respond_to?(:acs_set) && self.acs_set.present? && self.acs_set.stix_markings.select {|s| s.remote_object_field.blank? && s.isa_assertion_structure.present? && !s.isa_assertion_structure.marked_for_destruction? && !s.marked_for_destruction?}.collect(&:isa_assertion_structure).compact.first

      if object_classification.present?
        object_classification = object_classification.cs_classification
      else
        errors.add(:base,"#{self.class.to_s} must have an object level classification declaration")
        return
      end

      field_classifications = self.stix_markings.select {|s| s.remote_object_field.present? && s.isa_assertion_structure.present? && !s.isa_assertion_structure.marked_for_destruction? && !s.marked_for_destruction?}.map{|e| {e.remote_object_field.classify => e.isa_assertion_structure.cs_classification}}

      highest_field = Classification.determine_highest(field_classifications)

      if highest_field.present? && Classification::CLASSIFICATIONS.index(object_classification) < Classification::CLASSIFICATIONS.index(highest_field.values.first)
	      errors.add(:base,"Invalid Classification, Classification of the " + self.class.to_s + " is less than the classification of the " + highest_field.keys.first + " field")
      end

      if self.class.const_defined?("CLASSIFICATION_CONTAINER_OF")
	      assoc_classifications = []
	      self.class::CLASSIFICATION_CONTAINER_OF.each do |assoc|
		      a = self.send(assoc)
		      if a.class.to_s.include?("Collection") && a.present? && a.first.respond_to?(:portion_marking)
            assoc_class = self.send(assoc).collect(&:portion_marking)
            assoc_class.each do |c|
              assoc_classifications << {assoc.to_s.classify => c} if c.present?
            end if assoc_class.present?
		      elsif a.present? && a.respond_to?(:portion_marking)
						assoc_classifications << {assoc.to_s.classify => a.portion_marking} if a.portion_marking.present?
		      end
	      end
	      assoc_classifications.flatten!

	      highest_assoc = Classification.determine_highest(assoc_classifications)

	      if highest_assoc.present? && Classification::CLASSIFICATIONS.index(object_classification) < Classification::CLASSIFICATIONS.index(highest_assoc.values.first)
		      errors.add(:base,"Invalid Classification, Classification of the " + self.class.to_s + " is less than the classification of the contained " + highest_assoc.keys.first + " objects")
	      end
      end

      if self.class.const_defined?("CLASSIFICATION_CONTAINED_BY")
	      assoc_classifications = []
	      self.class::CLASSIFICATION_CONTAINED_BY.each do |assoc|
		      a = self.send(assoc)
		      if a.class.to_s.include?("Collection") && a.present? && a.first.respond_to?(:portion_marking)
            assoc_class = self.send(assoc).collect(&:portion_marking)

            assoc_class.each do |c|
		          assoc_classifications << {assoc.to_s.classify => c} if c.present?
            end if assoc_class.present?
		      elsif a.present? && a.respond_to?(:portion_marking)
			      assoc_classifications << {assoc.to_s.classify => a.portion_marking} if a.portion_marking.present?
		      end
	      end
	      assoc_classifications.flatten!

	      lowest_assoc = Classification.determine_lowest(assoc_classifications)
        
	      if lowest_assoc.present? && Classification::CLASSIFICATIONS.index(object_classification) > Classification::CLASSIFICATIONS.index(lowest_assoc.values.first)
		      errors.add(:base,"Invalid Classification, Classification of the " + self.class.to_s + " is greater than the classification of the " + lowest_assoc.keys.first + " containing this object")
	      end
      end
    end

    def set_portion_marking
      return unless self.respond_to?(:portion_marking)
      return if @is_upload

      markings = self.stix_markings.select {|s| s.remote_object_field.blank? }.collect(&:isa_assertion_structure).compact.first

      object_classification = markings unless markings.nil? || markings.destroyed?
      object_classification ||= self.acs_set.stix_markings.select {|s| s.remote_object_field.blank? }.collect(&:isa_assertion_structure).compact.first if self.respond_to?(:acs_set) && self.acs_set.present?

      if object_classification.present?
        object_classification = object_classification.cs_classification
        self.portion_marking = object_classification
        self.update_columns({portion_marking: object_classification})
        self.update_email_portion_markings if self.respond_to?(:update_email_portion_markings)
        self.reload
      end
    end
  end
end