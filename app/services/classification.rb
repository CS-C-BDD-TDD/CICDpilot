class Classification
  CLASSIFICATIONS = %w(U C S TS)

  class << self
    # Accepts an array of classification characters and returns the highest level classification
    def determine_highest(array)
      return if array.blank?
      value = -1
      highest = ''
      array.each do |cl|
        if CLASSIFICATIONS.index(cl.values.first) > value
          value = CLASSIFICATIONS.index(cl.values.first)
          highest = cl
        end
      end
      highest
    end

    # Accepts an array of classification characters and returns the lowest level classification
    def determine_lowest(array)
      return if array.blank?
      value = CLASSIFICATIONS.length
      lowest = ''
      array.each do |cl|
        if CLASSIFICATIONS.index(cl.values.first) < value
          value = CLASSIFICATIONS.index(cl.values.first)
          lowest = cl
        end
      end
      lowest
    end

    # Accepts an array of classification characters and returns the highest level classification
    def determine_highest_single(array)
      return if array.blank?
      value = -1
      highest = ''
      array.each do |cl|
        if CLASSIFICATIONS.index(cl) > value
          value = CLASSIFICATIONS.index(cl)
          highest = cl
        end
      end
      highest
    end

    # Accepts a single classification character value and returns array of classifications of lesser or equal value
    def list_allowable(classification)
      return CLASSIFICATIONS unless CLASSIFICATIONS.include?(classification)
      CLASSIFICATIONS[0..CLASSIFICATIONS.index(classification)]
    end

    # Accepts a single classification character value and returns array of classifications of greater or equal value
    def list_allowable_greater(classification)
      return CLASSIFICATIONS unless CLASSIFICATIONS.include?(classification)
      CLASSIFICATIONS[CLASSIFICATIONS.index(classification)..CLASSIFICATIONS.length]
    end

    def display_name(classification)
      case classification
        when 'C' then 'confidential'
        when 'S' then 'secret'
        when 'TS' then 'top secret'
        else
          'unclassified'
      end
    end

    # Accepts a params array with key values and returns a hash of values of that verify if classifications are correct
    def check_classifications(params)
      # return if classification is not enabled, also return if params are blank.
      return [] if params.blank? || Setting.CLASSIFICATION == false
      sm_holders = []
      classification_errors = []

      obj_level_classification = Classification.get_object_level_class(params)

      if obj_level_classification.blank?
        classification_errors << "#{params[:obj_type]} must have an object level classification declaration"
      end

      # if we made it this far the object level classification should be good
      # next we want to check fields, now field level classifications should all exist in the stix_markings_attributes so collect them first
      sm_fields = Classification.get_field_level_classifications(params[:stix_markings_attributes])
      
      if sm_fields.present?
        # now that we have all the fields and their classifications we want make sure they are not higher than the obj level
        sm_fields.each do |field|
          if field.values.present? && obj_level_classification.present? && Classification::CLASSIFICATIONS.index(field.values.first) > Classification::CLASSIFICATIONS.index(obj_level_classification)
            classification_errors << "Error in Field: #{field.keys.first}"
          end
        end
      end

      # okay now that we got here we are done with the original object checking, need to do associated objects and embedded objects.
      # We loop through the params array to find all valid keys that can contain stix markings attributes
      params.keys.each do |key|
        if StixMarking::VALID_CLASSES.include?(key.classify)
          sm_holders << key
        end
      end
      
      # now we have an array of all keys that could have stix markings. the first thing we need to do is find out the type of the main object were checking.
      # This should have been sent into the put as a parameter, we start with CLASSIFICATION_CONTAINER_OF
      if params[:obj_type].constantize.const_defined?("CLASSIFICATION_CONTAINER_OF")
        sm_holders.each do |holder|
          if params[:obj_type].constantize::CLASSIFICATION_CONTAINER_OF.include?(holder.to_sym)
            params[holder.to_sym].each_with_index do |obj, index|
              comparing_marking = Classification.get_object_level_class(obj, holder.classify.constantize)
              if comparing_marking.present? && obj_level_classification.present? && Classification::CLASSIFICATIONS.index(comparing_marking) > Classification::CLASSIFICATIONS.index(obj_level_classification)
                classification_errors << "Error in Contained Object: #{(holder + [index].to_s)}"
              end
            end
          end
        end
      end

      if params[:obj_type].constantize.const_defined?("CLASSIFICATION_CONTAINED_BY")
        sm_holders.each do |holder|
          if params[:obj_type].constantize::CLASSIFICATION_CONTAINED_BY.include?(holder.to_sym)
            params[holder.to_sym].each_with_index do |obj, index|
              comparing_marking = Classification.get_object_level_class(obj, holder.classify.constantize)
              if comparing_marking.present? && obj_level_classification.present? && Classification::CLASSIFICATIONS.index(obj_level_classification) > Classification::CLASSIFICATIONS.index(comparing_marking)
                classification_errors << "Error in Container Object: #{(holder + [index].to_s)}"
              end
            end
          end
        end
      end

      classification_errors
    end

    # returns the object level classification
    def get_object_level_class(params, obj_class = nil)
      # the real first thing we need to do is to find the object level marking, this will probably exist as an acs set or in the stix markings attributes
      if params[:acs_set_id].present?
        # if an acs_set_id exists pull the acs set with the id from the db and get the marking
        return AcsSet.find_by_guid(params[:acs_set_id]).portion_marking
      elsif params[:stix_markings_attributes].present?
        isa_markings = params[:stix_markings_attributes].select{|s| s[:remote_object_field] == nil && s[:isa_assertion_structure_attributes].present?}
        if isa_markings.present?
          # we get the first because their should only be 1 isa assertion marking with stix markings as remote_object_field nil, this should contain our classification
          isa_markings = isa_markings.first[:isa_assertion_structure_attributes]

          # i know sometimes cs_classification is in a array and sometimes its not so w/e check for array
          if isa_markings[:cs_classification].present?
            if isa_markings[:cs_classification].class == Array
              return isa_markings[:cs_classification].pop
            else
              return isa_markings[:cs_classification]
            end
          end

        end
      else
        # if we got here we must be just an associated object, if thats the case lets try and use the main id to find the object and pull the markings
        if params[:stix_id].present?
          markings_obj = obj_class.find_by_stix_id(params[:stix_id])
        elsif params[:cybox_object_id].present?
          markings_obj = obj_class.find_by_cybox_object_id(params[:cybox_object_id])
        elsif params[:guid].present?
          # if we reached the guid we must be an embedded object that doesnt have a stix id or a cybox object id -.-
          markings_obj = obj_class.find_by_guid(params[:guid])
        end

        # if the markings_obj is present get the classification from the portion marking
        if markings_obj.present?
          return markings_obj.portion_marking
        end
            
      end

      # return nil if we failed to find a object level classification marking
      nil
    end

    # returns a array of hashes with the key as the field name and the value as the classification
    def get_field_level_classifications(stix_markings)
      classifications = []

      field_markings = stix_markings.select {|sm| sm[:remote_object_field] != nil && sm[:isa_assertion_structure_attributes].present?}

      field_markings.each do |fm|
        # ugh again cs_classification is sometimes an array -.-
        if fm[:isa_assertion_structure_attributes][:cs_classification].class == Array
          classifications << {fm[:remote_object_field] => fm[:isa_assertion_structure_attributes][:cs_classification].pop}
        else
          classifications << {fm[:remote_object_field] => fm[:isa_assertion_structure_attributes][:cs_classification]}
        end
      end

      classifications
    end

  end
end