class IsaEntityCache < ActiveRecord::Base
  include Guidable
  include Transferable

  belongs_to  :user, primary_key: :guid, foreign_key: :user_guid

  validates_presence_of     :admin_org, :duty_org, :entity_class
  validate :valid_attributes

  before_create :set_defaults

  private

    def set_defaults
      if Rails.env == "development"
        self.life_cycle_status = 'DEV'
      elsif Rails.env == "test"
        self.life_cycle_status = 'TEST'
      else
        self.life_cycle_status = 'PROD'
      end
      self.clearance = 'U' unless self.clearance.present?
    end

    def valid_attributes
      klass = Stix::Native::IsaMarkingStructure

      unless ['PE', 'NPE'].include?(self.entity_class)
        errors.add('Entity Class',
          "'#{self.entity_class}' is an invalid entity class - Must be PE/NPE")
      end

      unless klass.validate_country(self.country)
        errors.add('Country',"'#{self.country}' is an invalid country")
      end

      unless ['U', 'C', 'S', 'TS'].include?(self.clearance)
        errors.add('Classification',
          "'#{self.clearance}' is an invalid classification")
      end

      if self.access_groups.present?
        self.access_groups.gsub(' ','').split(',').each do |x|
          unless Stix::Native::IsaMarkingStructure::ACCESS_GROUPS.include?(x)
            errors.add('Access Group',"'#{x}' is an invalid value")
          end
        end
      end

      if self.admin_org.present?
        unless klass.validate_org_dissemination(self.admin_org)
          errors.add('Admin Org',"'#{self.admin_org}' is an invalid value")
        end
      end

      if self.duty_org.present?
        unless klass.validate_org_dissemination(self.duty_org)
          errors.add('Duty Org',"'#{self.duty_org}' is an invalid value")
        end
      end

      if self.entity_type.present?
        unless klass.validate_entity(self.entity_type)
          errors.add('Entity Type',
            "'#{self.entity_type}' is an invalid Entity affiliation")
        end
      end

    end # End Method

end
