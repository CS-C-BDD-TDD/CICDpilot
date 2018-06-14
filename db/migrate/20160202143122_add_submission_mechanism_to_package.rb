class AddSubmissionMechanismToPackage < ActiveRecord::Migration
  def change
    add_column :stix_packages, :submission_mechanism, :string
  end
end
