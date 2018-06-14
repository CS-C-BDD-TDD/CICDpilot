class AddSrcFeedToUploadedFile < ActiveRecord::Migration
  def change
    # Add the source feed to stix packages for when we receive this
    # information from FLARE.
    add_column :uploaded_files, :src_feed, :string
  end
end

