class CiapIdMapping < ActiveRecord::Base

  validates_presence_of :before_id
  validates_presence_of :after_id

  include Auditable
  include Serialized
  
  self.table_name = "id_mappings"

  has_many :original_input_ciap_id_mappings
  has_many :original_inputs, through: :original_input_ciap_id_mappings

  attr_accessor :guid

  def self.mappings
    CiapIdMapping.all
  end

  alias_attribute :original_id, :before_id
  alias_attribute :sanitized_id, :after_id

end