class AddAisConsent < ActiveRecord::Migration
  def change
    create_table :ais_consent_marking_structures do |t|
      t.string  :consent
      t.boolean  :proprietary
      t.string  :color
      t.string  :stix_id
      t.string  :stix_marking_id
      t.string  :guid
    end
  end
end
