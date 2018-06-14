class CreateWeathermapImages < ActiveRecord::Migration
  def change
    create_table :weather_map_images do |t|
    	t.string :organization_token
    	t.integer :image_id
    	t.timestamps
    end

    add_index :weather_map_images, :image_id
  end
end
