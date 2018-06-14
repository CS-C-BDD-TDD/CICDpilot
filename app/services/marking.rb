class Marking
  class << self

    def clone_markings_into_package(obj, stix_package)
      inherited_markings = obj.dup()

      stix_markings ||= []

      # only clone in the object level markings.
      if inherited_markings.stix_markings.present?
        inherited_markings.stix_markings.each do |ihm|
          if ihm.remote_object_field == nil
            stix_markings << ihm
          end
        end
      end
      stix_markings.flatten!
      stix_markings << inherited_markings.acs_set.stix_markings if inherited_markings.acs_set.present?
      stix_markings.flatten!

      stix_markings.each do |markings|

        if markings.isa_marking_structure
          markings.isa_marking_structure.guid = nil
          markings.isa_marking_structure.stix_id = nil
          markings.isa_marking_structure.set_guid
          markings.isa_marking_structure.set_stix_id
        end

        if markings.isa_assertion_structure

          markings.isa_assertion_structure.isa_privs.each do |privs|
            privs.isa_assertion_structure_guid = nil
          end

          markings.isa_assertion_structure.further_sharings.each do |share|
            share.isa_assertion_structure_guid = nil
          end

          markings.isa_assertion_structure.guid = nil
          markings.isa_assertion_structure.stix_id = nil
          markings.isa_assertion_structure.set_guid
          markings.isa_assertion_structure.set_stix_id

          markings.isa_assertion_structure.isa_privs.each do |privs|
            privs.isa_assertion_structure_guid = markings.isa_assertion_structure.guid
          end

          markings.isa_assertion_structure.further_sharings.each do |share|
            share.isa_assertion_structure_guid = markings.isa_assertion_structure.guid
          end
        end

        markings.stix_id = nil
        markings.guid = nil
        markings.controlled_structure = nil
        markings.set_guid
        markings.set_stix_id
        markings.controlled_structure = "//*[@id=\"#{stix_package.stix_id}\"]//descendant-or-self::node()"
        if markings.isa_assertion_structure
          markings.isa_assertion_structure.stix_marking_id = markings.stix_id
        end
        if markings.isa_marking_structure
          markings.isa_marking_structure.stix_marking_id = markings.stix_id
        end
      end

      stix_markings
    end

    # takes in an markings argument and returns a copy without id's
    def remote_ids_from_args(markings)
      new_markings = markings.deep_dup
      # First get rid of the controlled structure
      new_markings.delete(:controlled_structure)
      # then get rid of the remote object type
      new_markings.delete(:remote_object_type)
      # Then start with the top level id's
      new_markings.delete(:id)
      # Then move onto the isa assertion structure
      new_markings[:isa_assertion_structure_attributes].delete(:id)
      new_markings[:isa_assertion_structure_attributes][:isa_privs_attributes].each do |ipa|
        ipa.delete(:id)
      end
      new_markings[:isa_assertion_structure_attributes][:isa_privs_attributes].each do |fsa|
        fsa.delete(:id)
      end
      # Next is the isa marking structure
      new_markings[:isa_marking_structure_attributes].delete(:id)
      new_markings[:isa_marking_structure_attributes].delete(:data_item_created_at)

      new_markings
    end

  end
end
