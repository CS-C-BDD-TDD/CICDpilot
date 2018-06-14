class DeleteConditionFromObservableValue < ActiveRecord::Migration
  class MIndicator < ActiveRecord::Base
    self.table_name = :stix_indicators
  end

  def up
    if ActiveRecord::Base.connection.instance_values["config"][:adapter]=='sqlite3'
      indicators = MIndicator.where("observable_value like '%| Condition: %'")

      indicators.find_each do |indicator|
        newValue = indicator.observable_value.remove(/ \| Condition: [^ \|,]*/)
        indicator.observable_value = newValue

        begin
          indicator.save!
        rescue StandardError => e
          puts "Could not change observable value for indicator #{indicator.id}, skipping indicator. Error: #{e.to_s}"
          indicator.save
        end
      end
    else
      execute "update stix_indicators set observable_value=regexp_replace(observable_value,' \\| Condition: [^ \\|,]*','') where observable_value like '%| Condition: %'"
    end
  end

  def down
  end
end
