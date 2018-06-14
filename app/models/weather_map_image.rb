class WeatherMapImage < ActiveRecord::Base
  belongs_to :original_input, foreign_key: :image_id
end
