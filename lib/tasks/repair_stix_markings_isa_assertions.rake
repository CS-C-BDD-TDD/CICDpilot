task :repair_stix_markings_isa_assertions => :environment do
  Indicator.find_in_batches do |batch|
    batch.each do |i|
    	if i.acs_set_id != nil
    		next
    	end
    	if i.stix_markings.blank?
    		Indicator.create_default_policy(i)
    		puts "Repaired #{i.title}, #{i.stix_id}"
    	else
  	  	i.stix_markings.each do |sm|
  	  		if sm.isa_assertion_structure.blank? && sm.isa_marking_structure != nil
  	  			Indicator.create_default_isa_assertion(i, sm)
  				puts "Repaired #{i.title}, #{i.stix_id}"
  	  		end
  	  	end
      end
    end
  end

  StixPackage.find_in_batches do |batch|
    batch.each do |sp|
    	if sp.acs_set_id != nil
    		next
    	end
    	if sp.stix_markings.blank?
    		StixPackage.create_default_policy(sp)
    		puts "Repaired #{sp.title}, #{sp.stix_id}"
    	else
  	  	sp.stix_markings.each do |spsm|
  	  		if spsm.isa_assertion_structure.blank? && spsm.isa_marking_structure != nil
  	  			StixPackage.create_default_isa_assertion(sp, spsm)
    				puts "Repaired #{sp.title}, #{sp.stix_id}"
  	  		end
  	  	end
      end
    end
  end

end
