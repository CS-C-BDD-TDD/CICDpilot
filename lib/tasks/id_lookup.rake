namespace :id_lookup do
  task :find => :environment do
    id = ENV['ID']
    list = ENV['LIST']
    if !id.nil?
      id_list=[id]
    elsif !list.nil?
      if File.file?(list)
        id_list=File.readlines(list).map(&:strip)
      else
        puts "File '#{list}' does not exist."
        exit
      end
    end
    id_list.each do |i|
      c=CiapIdMapping.where(before_id: i)
      if c.first.nil?
        puts "#{i}\t#{i}"
      else
        puts "#{i}\t#{c.first.after_id}"
      end
    end
  end
end
