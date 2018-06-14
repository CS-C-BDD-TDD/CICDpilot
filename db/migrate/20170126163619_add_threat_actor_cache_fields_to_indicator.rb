class AddThreatActorCacheFieldsToIndicator < ActiveRecord::Migration
  class MIndicator < ActiveRecord::Base
    self.table_name = "stix_indicators"
  end
  
  def up
    add_column :stix_indicators,:threat_actor_id,:text
    add_column :stix_indicators,:threat_actor_title,:text

    if MIndicator.count > 0
      # Migrate current threat actor data into indicators
      ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
      Indicator.find_in_batches.each do |indicators, batch|
        puts "Processing group ##{batch}"
        indicators.each do |indicator|
          begin
            indicator.set_threat_actor_value
          rescue Exception => e
            puts "Could not set threat actor value #{indicator.id}"
          end
        end
      end
      ::Sunspot.session = ::Sunspot.session.original_session
    end
  end

  def down
    remove_column :stix_indicators,:threat_actor_id
    remove_column :stix_indicators,:threat_actor_title
  end
end
