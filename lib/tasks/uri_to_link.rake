task :uri_to_link => :environment do |t, args|
  class Link < ActiveRecord::Base; self.table_name = 'cybox_links' end
  class Uri < ActiveRecord::Base; self.table_name = 'cybox_uris' end
  class Observable < ActiveRecord::Base; self.table_name = 'cybox_observables' end

  Uri.where('label is not null').each do |u|
    l = Link.create!(created_at:u.created_at,cybox_hash:u.cybox_hash,label:u.label,uri_object_id:u.cybox_object_id,updated_at:u.updated_at,guid:u.guid,cybox_object_id:SecureRandom.cybox_object_id(Link.new))
    obs = Observable.where('remote_object_id=?',u.cybox_object_id)
    obs.each do |o|
      o.remote_object_id = l.cybox_object_id
      o.remote_object_type = 'Link'
      o.save
    end
  end
end
