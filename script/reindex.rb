def check_model(model,id,guid)
  search=model.constantize.search do
    fulltext guid
  end
  check=false
  search.results.each do |s|
    if s.id==id
      check=true
    end
  end
  check
end

def timediff( starttime )
  currenttime = Time.now.to_i
  diff = currenttime - starttime
  hours = diff / 3600
  minutes = ( diff - ( hours * 3600 ) ) / 60
  seconds = diff - ( hours * 3600 ) - ( minutes * 60 )
  return '%d:%02d:%02d' % [ hours.to_s, minutes.to_s, seconds.to_s ]
end

def percent(count,total)
  result = (((count.to_f/total)*1000).to_int)/10.0
  result
end

def index_in_batch(bar,model)
  total=model.constantize.count
  indexed=0
  starttime = lasttime = Time.now.to_i
  if total>0
    update_output("  #{indexed} #{model.pluralize} indexed out of #{total} (#{percent(indexed,total)}%)")

    model.constantize.find_in_batches(batch_size: 100) do |batch|
      Sunspot.index(batch)
      indexed+=batch.count
      update_bar(bar,batch.count)
      total_diff = timediff(starttime)
      last_diff = timediff(lasttime)
      lasttime = Time.now.to_i
      update_output("  #{indexed} #{model.pluralize} indexed out of #{total} (#{percent(indexed,total)}%)  #{last_diff}/#{total_diff}")
    end
    f=File.open(@output_file_name,'a')
    f.write("#{model} complete\n")
    f.close
  end
end

def verify_and_index(bar,model)
  env_count=100

  indexed=new=0
  starttime = lasttime = Time.now.to_i

  object_ids = model.constantize.pluck(:id,:guid)

  total = object_ids.count

  if total>0
    update_output("  #{indexed} #{model.pluralize}, #{new} new are indexed out of #{indexed+new}/#{total} (#{percent(indexed+new,total)}%)")

    update_count=0
    object_ids.each do |id|
      if check_model(model,id[0],id[1])
        indexed+=1
        update_count+=1
      else
        i=model.constantize.find(id[0])
        i.index
        new+=1
        update_count+=1
      end
      if (indexed+new)%env_count==0
        update_bar(bar,update_count)
        update_count=0
        total_diff = timediff(starttime)
        last_diff = timediff(lasttime)
        lasttime = Time.now.to_i
        update_output("  #{indexed} #{model.pluralize}, #{new} new are indexed out of #{indexed+new}/#{total} (#{percent(indexed+new,total)}%)  #{last_diff}/#{total_diff}")
      end
    end
    if (indexed+new)%env_count
      update_bar(bar,update_count)
      total_diff = timediff(starttime)
      last_diff = timediff(lasttime)
      lasttime = Time.now.to_i
      update_output("  #{indexed} #{model.pluralize}, #{new} new are indexed out of #{indexed+new}/#{total} (#{percent(indexed+new,total)}%)  #{last_diff}/#{total_diff}")
    end
    f=File.open(@output_file_name,'a')
    f.write("#{model} complete\n")
    f.close
  end
  total
end

def update_output(text)
  print "\r\033[2K#{text}"
  STDOUT.flush
end

def update_bar(bar,amount)
  print "\033[1A"
  bar.increment!(amount)
  puts
end

update_output("Gathering information...")
rpm_name=`rpm -qa | grep ^cyber-indicators-`

development=false
if rpm_name.empty?
  development=true
  @output_file_name=Rails.root.to_s + "/log/reindex.log"
else
  system("mkdir -p /var/log/ciap_install")

  version=/^cyber-indicators-(.+?)\.x86_64$/.match(rpm_name)[1]

  @output_file_name="/var/log/ciap_install/#{version}.log"
end

completed=Hash.new
verify=false

if File.exist?(@output_file_name)
  file=File.readlines(@output_file_name)
  if file[-1]=="DONE\n"
    File.delete(@output_file_name)
  else
    update_output("Previous reindex log file found.\n  (C)ontinue previous reindex, (S)tart new reindex, or (Q)uit? (C/S/Q) ")
    input=""
    while !['C','S','Q','c','s','q'].include? input
      input=STDIN.getch
    end
    puts input
    if input=='Q' || input=='q'
      puts "Quit chosen...exiting"
      exit
    elsif input=='S' || input=='s'
      File.delete(@output_file_name)
    else
      verify=true
      file.each do |line|
        model=/^(.+?) complete/.match(line)
        if model
          completed[model[1]]=1
        end
      end
    end
  end
end

# No longer clearing out the index due to the amount of time it takes to rebuild
unless verify
  if development
    system("/usr/bin/curl -s -k 'http://localhost:8982/solr/development/update?commit=true' -H 'Content-Type: text/xml' --data-binary '<delete><query>*:*</query></delete>' > /dev/null 2> /dev/null")
  else
    system("/usr/bin/curl -s -k 'https://localhost:8983/solr/production/update?commit=true' -H 'Content-Type: text/xml' --data-binary '<delete><query>*:*</query></delete>' > /dev/null 2> /dev/null")
  end
  update_output("Cleared SOLR...")
  puts
end

Rails.logger.level=5
if development
  Sunspot::Rails::LogSubscriber.logger.level=5
end
Sunspot.config.pagination.default_per_page=255

Rails.application.eager_load!
models=ActiveRecord::Base.descendants

searchable_models=[]
total_records=0
models.each do |model|
  if model.searchable?
    searchable_models.push(model.name)
    total_records+=model.count
  end
end

# Create a blank file
f=File.open(@output_file_name,'a')
f.close

print "\r"
bar=ProgressBar.new(total_records)
bar.display
puts

searchable_models.sort.each do |model|

  if verify and completed[model]
    records=model.constantize.count
    update_bar(bar,records)
    next
  end

  if verify
# Used if the previous run failed during this model, to pick up where it left off
    indexed=verify_and_index(bar,model)
    if indexed>0
      verify=false
    end
  else
    index_in_batch(bar,model)
  end

end
puts
f=File.open(@output_file_name,'a')
f.write("DONE\n")
f.close
