class IsaAssertionStructure < ActiveRecord::Base
  has_many :isa_privs,
           primary_key: :guid,
           foreign_key: :isa_assertion_structure_guid, dependent: :destroy

  has_many :further_sharings,
           primary_key: :guid,
           foreign_key: :isa_assertion_structure_guid, dependent: :destroy

  belongs_to :stix_marking, primary_key: :stix_id, foreign_key: :stix_marking_id

  accepts_nested_attributes_for :isa_privs
  accepts_nested_attributes_for :further_sharings, allow_destroy: true, reject_if: proc {|attributes| attributes['scope'].blank?}

  before_validation :set_classification if Setting.CLASSIFICATION == false

  before_save :clear_assertions

  validate :valid_isa_attributes
  validate :public_release_by
  validate :check_classifications if Setting.CLASSIFICATION == true

  include Auditable
  include Guidable
  include Stixable
  include Transferable

  def self.ingest(uploader, marking, msobj)
    s = IsaAssertionStructure.new
    s.stix_marking_id = marking.stix_id
    s.set_guid             # Needed to support links to ISA privs, if any
    s.stix_id = msobj.stix_id
    s.set_stix_id
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      s.stix_id = s.stix_id + Setting.READ_ONLY_EXT
      s.guid = s.guid + Setting.READ_ONLY_EXT
    end

    s.cs_classification = msobj.cs_classification
    s.cs_cui = msobj.cs_cui
    s.cs_countries = msobj.cs_countries
    s.cs_entity = msobj.cs_entity
    s.cs_formal_determination = msobj.cs_formal_determination
    s.cs_orgs = msobj.cs_orgs
    s.cs_shargrp = msobj.cs_shargrp
    s.is_default_marking = msobj.is_default_marking 
    s.is_default_marking = false if s.is_default_marking.nil?
    s.privilege_default = msobj.privilege_default
    s.privilege_default = 'deny' if s.privilege_default.nil?
    s.public_release = msobj.public_release
    s.public_release = false if s.public_release.nil?
    s.public_released_by = msobj.public_released_by
    s.public_released_on = msobj.public_released_on.nil? ? nil : msobj.public_released_on + 12.hours
    s.classified_by = msobj.classified_by
    s.classification_reason = msobj.classification_reason
    s.classified_on = msobj.classified_on.nil? ? nil : msobj.classified_on + 12.hours

    if msobj.privs
      msobj.privs.each do |pobj|
        p = IsaPriv.new
        p.isa_assertion_structure_guid = s.guid
        p.action = pobj.action
        p.effect = pobj.effect
        p.scope_countries = pobj.scope_countries
        p.scope_entity = pobj.scope_entity
        p.scope_is_all = pobj.scope_is_all
        p.scope_orgs = pobj.scope_orgs
        p.scope_shargrp = pobj.scope_shargrp

        s.isa_privs << p
      end
    end

    if msobj.further_sharings
      msobj.further_sharings.each do |fobj|
        f = FurtherSharing.new
        f.isa_assertion_structure_guid = s.guid
        f.effect = fobj.effect
        f.scope = fobj.scope

        s.further_sharings << f
      end
    end

    s
  end

  # Returns a tokenized ControlSet as defined in the ACS 2.0 standard.
  def control_set
    tokens = []

    lst = build_tokens('CLS', cs_classification)
    tokens << lst unless lst.nil?
    lst = build_tokens('SENS', cs_cui)
    tokens << lst unless lst.nil?
    lst = build_tokens('ENTITY', cs_entity)
    tokens << lst unless lst.nil?
    lst = build_tokens('FD', cs_formal_determination)
    tokens << lst unless lst.nil?
    tokens << 'FD:PUBREL' if public_release && !tokens.flatten.include?("FD:PUBREL")
    lst = build_tokens('ORG', cs_orgs)
    tokens << lst unless lst.nil?
    lst = build_tokens('SHAR', cs_shargrp)
    tokens << lst unless lst.nil?
    lst = build_tokens('CVT', cs_info_caveat)
    tokens << lst unless lst.nil?
    lst = build_tokens('CTRY', cs_countries)
    tokens << lst unless lst.nil?
    
    tokens.flatten!
    tokens.join(' ')
  end

  def fd_ais?
    return false if self.cs_formal_determination.blank?
    return self.cs_formal_determination.include?('AIS')
  end

  def privilege_default
    if self.isa_privs.count > 0
      'deny'
    else
      read_attribute(:privilege_default)
    end
  end
  
  private

    def set_classification
      write_attribute(:cs_classification,'U') if self.cs_classification.blank?
    end

    def build_tokens(prefix, csv)
      return nil if csv.nil?
      arr = csv.gsub(' ','').split(',')
      arr.collect { |x| "#{prefix}:#{x}" }
    end

    def set_public_release_info
      return unless self.public_release
      self.public_released_on ||= Time.now
      self.cs_formal_determination ||= "PUBREL"
    end

    def clear_assertions
      if self.public_release || (self.cs_formal_determination && self.cs_formal_determination.include?("PUBREL"))
        self.cs_countries = nil
        self.cs_cui = nil
        self.cs_entity=nil
        self.cs_orgs=nil
        self.cs_shargrp=nil
        self.cs_info_caveat=nil

        if self.public_release
          if self.cs_formal_determination.blank? || (self.cs_formal_determination.present? && self.cs_formal_determination.exclude?("PUBREL"))
            self.cs_formal_determination << "PUBREL"
          end        
          self.cs_classification='U'
        end
      end
    end

    def public_release_by
      return unless self.public_release
      if self.public_released_by.blank?
        errors.add('Released By',"can't be blank")
      elsif self.public_released_by.length > 254
        errors.add('Released by', "can't be longer than 255 characters.")
      end
    end

    def valid_isa_attributes
      # TODO: Should become an ISAAssertionStructure (in the gem)
      klass = Stix::Native::IsaMarkingStructure

      if self.cs_countries.present?
        self.cs_countries.gsub(' ','').split(',').each do |x|
          unless klass.validate_country(x)
            errors.add('Country',"'#{x}' is an invalid country")
          end
        end
      end

      unless ['U', 'C', 'S', 'TS'].include?(self.cs_classification)
        errors.add('Classification',"'#{self.cs_classification}' is an invalid classification")
      end

      unless Setting.CLASSIFICATION
				if self.cs_classification.present? && self.cs_classification != 'U'
					errors.add('Classification',"Classified Document uploaded to Unclassified System.  Contact System Adminstrator to report Data Spillage")
				end
			end

      if self.cs_cui.present?
        self.cs_cui.gsub(' ','').split(',').each do |x|
          unless klass.validate_cui(x)
            errors.add('CUI (Controlled Unclassified Info)',"'#{x}' is an invalid CUI value")
          end
        end
      end

      if self.cs_entity.present?
        self.cs_entity.gsub(' ','').split(',').each do |x|
          unless klass.validate_entity(x)
            errors.add('Entity',"'#{x}' is an invalid Entity affiliation")
          end
        end
      end

      if self.cs_formal_determination.present?
        self.cs_formal_determination.gsub(' ','').split(',').each do |x|
          unless klass.validate_formal_determination(x)
            errors.add('Formal Determination',"'#{x}' is an invalid value")
          end
        end
      end

      if self.cs_orgs.present?
        self.cs_orgs.gsub(' ','').split(',').each do |x|
          unless klass.validate_org_dissemination(x)
            errors.add('Organization Restriction',"'#{x}' is an invalid value")
          end
        end
      end

      # NOT NEEDED UNTIL WE DO TS-CIAP
      #if self.cs_info_caveat.present?
      #  self.cs_info_caveat.gsub(' ','').split(',').each do |x|
      #    unless klass.validate_info_caveat(x)
      #      errors.add('Info Caveat',"'#{x}' is an invalid value")
      #    end
      #  end
      #end

      if self.cs_shargrp.present?
        self.cs_shargrp.gsub(' ','').split(',').each do |x|
          unless klass.validate_shareability(x)
            errors.add('Sharebaility Group',"'#{x}' is an invalid value")
          end
        end
      end

      errors.present?
    end

    def check_classifications
      if self.cs_classification.blank?
        errors.add('Classification', "Can't be blank")
      end
      if self.cs_classification != 'U' && (self.classified_by.blank? || self.classified_on.blank? || self.classification_reason.blank?)
        errors.add('Classified On, Classified By and Classification Reason', "can't be blank if classification is not unclassified. Original Classification must be present.")
      end
      if self.classified_on.present? && self.classified_on.future?
        errors.add(:classified_on, "Classified On can't be greater than the present date.")
      end
    end

end
