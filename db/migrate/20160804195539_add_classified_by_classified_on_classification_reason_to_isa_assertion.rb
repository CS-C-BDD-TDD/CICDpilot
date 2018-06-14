class AddClassifiedByClassifiedOnClassificationReasonToIsaAssertion < ActiveRecord::Migration
  def change
  	add_column :isa_assertion_structures, :classified_by, :string
  	add_column :isa_assertion_structures, :classified_on, :datetime
	add_column :isa_assertion_structures, :classification_reason, :string
  end
end
