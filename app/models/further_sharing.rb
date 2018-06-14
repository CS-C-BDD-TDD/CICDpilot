class FurtherSharing < ActiveRecord::Base
  belongs_to :isa_assertion_structure, primary_key: :guid, foreign_key: :isa_assertion_structure_guid

  include Auditable
  include Guidable
  include Transferable

  validates_presence_of :scope
  validate :valid_scope

  def effect=(effect)
    if effect == 'permit' || effect == 'deny'
      write_attribute(:effect,effect)
    elsif effect == 'true' || effect == true
      write_attribute(:effect, 'permit')
    elsif effect == 'false' || effect == false
      write_attribute(:effect, 'deny')
    end
  end

  def valid_scope
    return unless self.scope.present?

    self.scope.gsub(' ','').split(',').each do |x|
      unless Stix::Native::IsaMarkingStructure.validate_further_sharing_org(x)
        errors.add('Organization Restriction',"'#{x}' is an invalid value")
      end
    end
  end

end
