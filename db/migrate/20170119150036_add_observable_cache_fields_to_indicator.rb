class AddObservableCacheFieldsToIndicator < ActiveRecord::Migration
  class MIndicator < ActiveRecord::Base
    self.table_name = "stix_indicators"
  end

  def up
    add_column :stix_indicators,:observable_type,:string
    add_column :stix_indicators,:observable_value,:text

    if MIndicator.count > 0
      # Migrate current observable data into indicators
      ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
      Indicator.find_in_batches.with_index do |indicators, batch|
        puts "Processing group ##{batch}"
        indicators.each do |indicator|
          begin
            indicator.set_observable_value
          rescue Exception => e
            puts "Error in processing #{indicator.stix_id}."
          end
        end
      end
      ::Sunspot.session = ::Sunspot.session.original_session
    end
  end

  def down
    remove_column :stix_indicators,:observable_type
    remove_column :stix_indicators,:observable_value
  end
end
