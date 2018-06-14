task :acs_set_repair => :environment do
  sets_to_repair = AcsSet.all.select{ |a| a.stix_markings.blank? }
  sets_to_repair.each do |set|
    object = set.indicators.joins(:stix_markings).joins(stix_markings: :isa_assertion_structure).first
    object ||= set.stix_packages.joins(:stix_markings).joins(stix_markings: :isa_assertion_structure).first
    if object.blank?
      set.destroy
      next
    end

    sm = object.stix_markings.joins(:isa_assertion_structure).first
    im = sm.isa_marking_structure
    ia = sm.isa_assertion_structure

    sm.remote_object = set
    sm.save!

    puts "Repaired #{set.name} from #{object.class.to_s} #{object.stix_id}"
  end
end
