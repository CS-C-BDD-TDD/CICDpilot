class AddAisFlagToIndicators < ActiveRecord::Migration
  class MStixPackage < ActiveRecord::Base
    self.table_name = :stix_packages
    has_many :stix_markings, primary_key: :guid, as: :remote_object, dependent: :destroy
    has_many :isa_assertion_structures, primary_key: :stix_id, through: :stix_markings, dependent: :destroy
    has_many :ais_consent_marking_structures, primary_key: :stix_id, through: :stix_markings, dependent: :destroy
    has_many :indicators_packages, primary_key: :stix_id, foreign_key: :stix_package_id, dependent: :destroy
    has_many :indicators, through: :indicators_packages
  end

  class MObservable < ActiveRecord::Base
    self.table_name = :observables
  end

  class MIndicator < ActiveRecord::Base
    self.table_name = :stix_indicators
    has_many :indicators_packages, primary_key: :stix_id, foreign_key: :stix_indicator_id, dependent: :destroy
    has_many :stix_packages, through: :indicators_packages
    # This is an association to the isa_assertion_structures in the
    # associated stix_package.
    has_many :isa_assertion_structures, primary_key: :stix_id, through: :stix_packages, dependent: :destroy
  end

  def up
    add_column :stix_indicators, :is_ais, :boolean, default: false

    MIndicator.reset_column_information

    MIndicator.joins(:stix_packages).joins(:isa_assertion_structures).where("isa_assertion_structures.cs_formal_determination LIKE '%AIS%'").update_all(is_ais: true)
    MIndicator.joins(:stix_packages).joins(stix_packages: :ais_consent_marking_structures).update_all(is_ais: true)
  end

  def down
    remove_column :stix_indicators, :is_ais
  end
end