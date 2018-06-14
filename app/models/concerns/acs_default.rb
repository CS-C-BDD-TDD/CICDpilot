module AcsDefault

  ASSERTION_DEFAULTS = {cs_classification: 'U', cs_orgs: 'USA.USG', privilege_default: 'deny',public_release: false}
  MARKING_DEFAULTS = {re_custodian: 'USA.DHS.US-CERT'}
  PRIVS_DEFAULTS = [
      {action:'DSPLY',effect: 'permit',scope_is_all: true},
      {action:'IDSRC',effect: 'deny',scope_is_all: true},
      {action:'TENOT',effect: 'deny',scope_is_all: true},
      {action:'NETDEF',effect: 'permit',scope_is_all: true},
      {action:'LEGAL',effect: 'deny',scope_is_all: true},
      {action:'INTEL',effect: 'permit',scope_is_all: true},
      {action:'TEARLINE',effect: 'permit',scope_is_all: true},
      {action:'OPACTION',effect: 'permit',scope_is_all: true},
      {action:'REQUEST',effect: 'permit',scope_is_all: true},
      {action:'ANONYMOUSACCESS',effect: 'deny',scope_is_all: true}
  ]

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def apply_default_policy_if_needed(obj, is_recursive = false)
      obj.reload if obj.id.present?
      if StixMarking::VALID_CLASSES.include?(obj.class.to_s)        
        # check to make sure each stix marking has an isa assertion and a isa marking
        if !obj.stix_markings.blank?
          obj.stix_markings.each do |e|
            isa_marking_count = 0
            isa_assertion_count = 0

            if obj.respond_to?(:acs_set_id) && obj.acs_set_id.present?
              isa_assertion_count += 1
            end

            # need to take into account stix markings that have isa markings/assertions in different markings
            if e.isa_marking_structure.blank?
              # check the rest of the markings to see if we have a isa marking for this field
              other_markings = obj.stix_markings.select { |i| i.stix_id != e.stix_id && i.remote_object_field == e.remote_object_field }

              if !other_markings.blank?
                other_markings.each do |i|
                  if !i.isa_marking_structure.blank?
                    isa_marking_count += 1
                  end
                end
              end
            else
              isa_marking_count += 1
            end

            if e.isa_assertion_structure.blank?
              # check the rest of the markings to see if we have a isa assertion for this field
              other_markings = obj.stix_markings.select { |i| i.stix_id != e.stix_id && i.remote_object_field == e.remote_object_field }

              if !other_markings.blank?
                other_markings.each do |i|
                  if !i.isa_assertion_structure.blank?
                    isa_assertion_count += 1
                  end
                end
              end
            else
              isa_assertion_count += 1
            end
            # Check for a blank marking structure
            create_default_isa_structure(obj, e) if isa_marking_count == 0
            # Check for a blank assertion structure
            create_default_isa_assertion(obj, e) if isa_assertion_count == 0
            # reload the markings so we can see everything that was made
            e.reload
          end
        else
          # else if no stix markings at all create 
          create_default_policy(obj)
        end
        # reload the object to set the pm
        obj.reload if obj.id.present?
        obj.set_portion_marking if obj.respond_to?(:set_portion_marking)
      end
    end

    # Creates a default access policy for a resource. The object passed in
    # should be either a StixPackage or an Indicator.

    def create_default_policy(obj)
      m = create_default_marking(obj)
      create_default_isa_structure(obj,m) if obj.isa_marking_structures.count == 0
      create_default_isa_assertion(obj,m) if obj.isa_assertion_structures.count == 0
      # This will set the portion markings on indicators and packages
      # associated with the STIX markings after the ISA Assertion Structures
      # have been created with default policies.
      m.reload
    end

    # Creates entry in the join table between Markings and Marking Structures.



    # Creates a default Marking for a Package or Indicator.

    def create_default_marking(obj)
      m = StixMarking.new
      m.is_reference = false
      m.remote_object_id = obj.guid
      m.remote_object_type = obj.class.to_s
      if obj.respond_to?(:set_controlled_structure)
        obj.set_controlled_structure(m)
      elsif obj.respond_to?(:cybox_object_id)
        # for cybox objects, need to verify the correctness of this.
        m.controlled_structure =
            "//cybox:Object[@id='#{obj.cybox_object_id}']/" +
                'descendant-or-self::node()'
        m.controlled_structure += "| #{m.controlled_structure}/@*"
      end
      m.save
      m
    end

    # Creates an ISA Marking Structure of type "ISAMarkingsType".

    def create_default_isa_structure(obj,m)
      ms = IsaMarkingStructure.new(MARKING_DEFAULTS)
      ms.data_item_created_at = (defined? obj.created_at) ? obj.created_at : Time.now
      ms.stix_marking = m
      ms.save
      ms
    end

    # Creates an ISA Marking Structure of type "ISAMarkingsAssertionType".

    def create_default_isa_assertion(obj,m)
      ms = IsaAssertionStructure.new(ASSERTION_DEFAULTS)
      # when setting a default marking set the classification to U this was set to blank for UI purposes
      ms.cs_classification = 'U'

      # Default markings are ONLY allowed at the Package level
      if obj.class.to_s == 'StixPackage'
        ms.is_default_marking = true
      else
        ms.is_default_marking = false
      end
      ms.stix_marking = m
      ms.save

      create_default_privs(ms)
      ms
    end

    def create_default_privs(ms)
      PRIVS_DEFAULTS.each do |priv_attrs|
        i = IsaPriv.new(priv_attrs)
        i.isa_assertion_structure_guid = ms.guid
        i.save
      end
    end

  end # ClassMethods

end
