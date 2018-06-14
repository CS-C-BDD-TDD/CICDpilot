class IndicatorZip < ActiveRecord::Base
  belongs_to :uploaded_file
  belongs_to :indicator
end
