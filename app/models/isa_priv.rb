class IsaPriv < ActiveRecord::Base
  belongs_to :isa_assertion_structure, primary_key: :guid, foreign_key: :isa_assertion_structure_guid

  validate :valid_privs

  include Auditable
  include Guidable
  include Transferable

  def scope
    return 'ALL' if scope_is_all
    tokens = []

    lst = build_tokens('CTRY', scope_countries)
    tokens << lst unless lst.nil?
    lst = build_tokens('ENTITY', scope_entity)
    tokens << lst unless lst.nil?
    lst = build_tokens('ORGS', scope_orgs)
    tokens << lst unless lst.nil?
    lst = build_tokens('SHARGRP', scope_shargrp)
    tokens << lst unless lst.nil?

    tokens.flatten!
    tokens.join(' ')
  end

  def effect=(effect)
    if effect == 'permit' || effect == 'deny'
      write_attribute(:effect,effect)
    elsif effect == 'true' || effect == true
      write_attribute(:effect, 'permit')
    elsif effect == 'false' || effect == false
      write_attribute(:effect, 'deny')
    end
  end

  private

  def build_tokens(prefix, csv)
    return nil if csv.nil?
    arr = csv.gsub(' ','').split(',')
    arr.collect { |x| "#{prefix}:#{x}" }
  end

  def valid_privs
    klass = Stix::Native::IsaMarkingStructure

    if self.scope_countries.present?
      self.scope_countries.gsub(' ','').split(',').each do |x|
        unless klass.validate_country(x)
          errors.add('Scope: Country',"'#{x}' is an invalid country")
        end
      end
    end

    if self.scope_entity.present?
      self.scope_entity.gsub(' ','').split(',').each do |x|
        unless klass.validate_entity(x)
          errors.add('Scope: Entity',"'#{x}' is an invalid Entity affiliation")
        end
      end
    end

    if self.scope_orgs.present?
      self.scope_orgs.gsub(' ','').split(',').each do |x|
        unless klass.validate_org_dissemination(x)
          errors.add('Scope: Organization',"'#{x}' is an invalid value")
        end
      end
    end

    if self.scope_shargrp.present?
      self.scope_shargrp.gsub(' ','').split(',').each do |x|
        unless klass.validate_shareability(x)
          errors.add('Scope: Shareability Group',"'#{x}' is an invalid value")
        end
      end
    end

    errors.present?
  end
end
