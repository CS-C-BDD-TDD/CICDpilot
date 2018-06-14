class OriginalInputCiapIdMapping < ActiveRecord::Base
  self.table_name="original_input_id_mappings"

  belongs_to :original_input
  belongs_to :ciap_id_mapping
end
