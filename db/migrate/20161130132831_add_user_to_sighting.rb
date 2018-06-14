class AddUserToSighting < ActiveRecord::Migration
  def up
    add_column :stix_sightings, :user_guid, :string

    Sighting.reset_column_information

    Sighting.includes(:indicator).where.not(indicator: nil).find_each { |s|
      if s.indicator.present?
        # Set the user of existing sightings to the user who created the
        # parent indicator if one exists.
        user_guid = s.indicator.created_by_user_guid
        s.update_columns({user_guid: user_guid})
      end
    }
  end

  def down
    remove_column :stix_sightings, :user_guid
  end

end
