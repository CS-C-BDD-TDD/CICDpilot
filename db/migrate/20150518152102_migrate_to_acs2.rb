class MigrateToAcs2 < ActiveRecord::Migration

  ORGMAP = {
             # ACS 1.1           ACS 2.0               Notes
             # ----------     ---------------------   -----------------------------------------------
             'AFCYBER'     => 'USA.DOD.AFCYBER',    # US Air Force Cyber Command
             'ARCYBER'     => 'USA.DOD.ARCYBER',    # US Army Cyber Command
             'C10F'        => 'USA.DOD.C10F',       # US Navy Fleet Cyber Command
             'CIA'         => 'USA.CIA',            # Central Intelligence Agency
             'DEA'         => 'USA.DOJ.DEA',        # Drug Enforcement Agency
             'DHS'         => 'USA.DHS',            # Department of Homeland Security
             'DIA'         => 'USA.DIA',            # Defense Intelligence Agency
             'DNI'         => 'USA.DNI',            # Office of the Director of National Intelligence
             'DOC'         => 'USA.DOC',            # Department of Commerce
             'DOD'         => 'USA.DOD',            # Department of Defense
             'DOE'         => 'USA.DOE',            # Department of Energy
             'DOJ'         => 'USA.DOJ',            # Department of Justice
             'EOP'         => 'USA.EOP',            # Executive Office of the President
             'FBI'         => 'USA.DOJ.FBI',        # Federal Bureau of Investigation
             'GSA'         => 'USA.GSA',            # General Services Administration
             'MARFORCYBER' => 'USA.DOD.MARFORCYBER',# Marine Corps Cyberspace Command
             'NASA'        => 'USA.NASA',           # National Aeronautics and Space Administration
             'NRO'         => 'USA.NRO',            # National Reconnaissance Office
             'NSA'         => 'USA.NSA',            # National Security Agency
             'TREAS'       => 'USA.TREAS',          # Department of Treasury
             'USA'         => 'USA.DOD.USA',        # US Army
             'USAF'        => 'USA.DOD.USAF',       # US Air Force
             'USCYBERCOM'  => 'USA.DOD.USCYBERCOM', # US Cyber Command
             'USCG'        => 'USA.DHS.USCG',       # US Coast Guard
             'USG'         => 'USA.USG',            # US Government (for dissemination purposes only)
             'USMC'        => 'USA.DOD.USMC',       # US Marine Corps
             'USN'         => 'USA.DOD.USN',        # US Navy
             'USSTRATCOM'  => 'USA.DOD.USSTRATCOM', # US Strategic Command
             'OtherUSG'    => 'USA.USG',            # Other United States Federal Government
             'SLTT'        => 'USA.SLTT'            # State, Local, Tribal, Territorial Government
           }

  # The class for the top-level STIXMarking record

  class MStixMarking < ActiveRecord::Base
    self.table_name = 'stix_markings'
  end

  # The class for the old ACS 1.1 Markings

  class MIsaMarking < ActiveRecord::Base
    self.table_name = 'isa_markings'
  end

  # The class for the new ACS 2.0 ISA Marking Structures

  class MIsaMarkingStructure < ActiveRecord::Base
    self.table_name = 'isa_marking_structures'
  end

  # Note that community dissemination does not migrate from ACS 1.1 to 2.0.

  def up
    MIsaMarking.all.each do |old|
      parent = MStixMarking.where(:stix_id => old.stix_marking_id).first
      unless parent.present?
        puts("Orphan ISA Marking skipped")
        next
      end

      # Reset the type of the parent record
      parent.marking_model_type = 'ISAMarkingsType'
      parent.marking_model_name = 'ISA'
      parent.save

      # This will be the new ISAMarkingsType record; linked to original parent
      z = MIsaMarkingStructure.new
      z.re_data_item_created_at = old.data_item_created_at
      z.re_custodian = 'USA.DHS.US-CERT'
      z.stix_marking_guid = parent.guid
      z.save

      # Create new parent STIX Marking for the ISAMarkingsAssertionType record
      new_parent = MStixMarking.new
      new_parent.controlled_structure = parent.controlled_structure
      new_parent.guid = SecureRandom.uuid
      new_parent.is_reference = false
      new_parent.marking_model_name = 'ISA'
      new_parent.marking_model_type = 'ISAMarkingsAssertionType'
      new_parent.remote_object_id = parent.remote_object_id
      new_parent.remote_object_type = parent.remote_object_type
      new_parent.stix_id = SecureRandom.stix_id(new_parent)
      new_parent.save

      # This will be the new ISAMarkingsAssertionType record
      x = MIsaMarkingStructure.new
      x.is_default_marking = false
      x.privilege_default = 'deny'
      x.public_release = old.public_release
      if x.public_release
        # Tricky, but I've seen this in real examples
        x.public_released_by = '__AVAILABLE_ON_REQUEST__'
      end
      x.guid = SecureRandom.uuid
      x.stix_marking_guid = new_parent.guid

      # Convert all the ControlSet tokens

      x.cs_classification = 'U'
      x.cs_countries = convert_countries(old.releasable_to)
      x.cs_cui = convert_dissemination_controls(old.dissemination_controls)
      x.cs_formal_determination = convert_formal_determination(old.dissemination_controls)
      x.cs_entity = convert_entity(old.user_status_dissemination)
      x.cs_orgs = convert_orgs(old.org_dissemination)

      newarr = []
      if old.org_dissemination.present?
        arr = old.org_dissemination.gsub(' ', '').split(',')
        newarr << 'CIKR' if arr.include?('CIKR')
        newarr << 'CDC' if arr.include?('CDC')
        newarr << 'ISAC' if arr.include?('ISAC')
        x.cs_shargrp = newarr.join(', ') if newarr.present?
      end

      x.save
    end
  end

  def convert_countries(val)
    return nil if val.nil?
    arr = val.gsub(' ', '').split(',')
    newarr  = []
    arr.each do |v|
      if Stix::Native::IsaMarkingStructure.validate_country(v)
        newarr << v
      else
        puts("Releaseable To (Country): #{v} was not migrated")
      end
    end
    newarr.present? ? newarr.join(', ') : nil
  end

  def convert_dissemination_controls(val)
    return nil if val.nil?
    arr = val.gsub(' ', '').split(',')
    newarr = []
    arr.each do |v|
      
      case v
        when 'FOUO'   then newarr << v
        when 'PR'     then newarr << 'PROPIN'
        when 'LES'    then newarr << 'LES'
        when 'LESNF'  then newarr << 'LES'
      end
    end
    newarr.present? ? newarr.join(', ') : nil
  end

  def convert_formal_determination(val)
    return nil if val.nil?
    arr = val.gsub(' ', '').split(',')
    newarr = []
    arr.each do |v|
      
      case v
        when 'OC'   then newarr << v
        when 'NF'   then newarr << v
      end
    end
    newarr.present? ? newarr.join(', ') : nil
  end

  def convert_entity(val)
    return nil if val.nil?
    arr = val.gsub(' ', '').split(',')
    newarr = []
    arr.each do |v|
      
      case v
        # PE's ----------------------
        when 'CTR'   then newarr << v
        when 'GOV'   then newarr << v
        when 'MIL'   then newarr << v
        # NPE's ---------------------
        when 'DEV'   then newarr << v
        when 'NET'   then newarr << v
        when 'SVC'   then newarr << v
        when 'SVR'   then newarr << v
        else
          puts("Entity: #{v} was not migrated")
      end
    end
    newarr.present? ? newarr.join(', ') : nil
  end

  def convert_orgs(val)
    return nil if val.nil?
    arr = val.gsub(' ', '').split(',')
    newarr  = []
    arr.each do |v|
      if ORGMAP[v]
        newarr << ORGMAP[v]
      else
        unless v == 'CDC' || v == 'CIKR' || v == 'ISAC'
          puts("Releaseable To (Country): #{v} was not migrated")
        end
      end
    end
    newarr.present? ? newarr.join(', ') : nil
  end

end
