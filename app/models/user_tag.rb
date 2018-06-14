class UserTag < ActiveRecord::Base
  self.table_name = 'tags'
  
  def self.default_scope
    where 'tags.user_guid IS NOT NULL'
  end  

  validates_uniqueness_of :name,scope: :user_guid
  validates_presence_of :name
  
  include Auditable
  include Guidable
  include Serialized
  include Transferable
  
  has_many :indicators, 
           through: :tag_assignments,
           primary_key: :guid,
           foreign_key: :remote_object_guid,
           source: :remote_object, 
           source_type: 'Indicator'         

  has_many :tag_assignments,
           foreign_key: :tag_guid,
           primary_key: :guid,
           dependent: :destroy

  belongs_to :user, 
             foreign_key: :user_guid, 
             primary_key: :guid

  def name=(value)
    write_attribute(:name, value)
    lowercase = value.downcase if value
    write_attribute(:name_normalized, lowercase)
  end

end
