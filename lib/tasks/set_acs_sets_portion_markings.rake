task :set_acs_sets_portion_markings => :environment do
  AcsSet.find_in_batches do |batch|
    batch.each do |acs|
    	if acs.portion_marking.blank?
    		acs.set_portion_marking
    		puts "Set ACS Portion Marking #{acs.title}, #{acs.stix_id}"
      end
    end
  end

end
