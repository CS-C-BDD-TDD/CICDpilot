# When ORIGNAL_INPUT.INPUT_CATEGORY is set to 'Upgrade', this new column will
# hold values of:
#
# 1. Human Review Pending - For Human Review XML files ingested via CIAP Human
#    Review path that need to be reviewed in the Human Review feature.
#
# 2. Human Review Transfer - For Human Review XML files stored in ECIS that
#    need to be transferred to CIAP.
#
# 3. Human Review Completed - For Human Review XML files stored in CIAP that
#    have gone through Human Review, had the resulting edits re-applied to the
#    XML, and had the original XML (with its PII) replaced by the edited XML.
#
# 4. Sanitized - For sanitized XML files stored in ECIS that need to be
#    re-disseminated.

class AddInputSubCategoryToOriginalInput < ActiveRecord::Migration
  def change
    add_column :original_input, :input_sub_category, :string
  end
end
