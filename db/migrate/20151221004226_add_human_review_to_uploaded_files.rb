class AddHumanReviewToUploadedFiles < ActiveRecord::Migration

  # The new column records whether an incoming STIX XML file requires
  # human review before it can be ingested coompletely. This is in support
  # of the Automated Indicator Sharing (AIS) initiative.

  def up
    add_column :uploaded_files, :human_review_needed, :boolean, default: false
  end

  def down
    remove_column :uploaded_files, :human_review_needed
  end

end
