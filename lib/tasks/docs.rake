require 'erb'

namespace :docs do

  def make_docs()
    doc_home = Pathname.new ENV['DOC_HOME']||ENV['DOC_PATH']||Rails.root.join('script/deployment/var/apps/cyber-indicators/doc/templates').to_s
    out_path = Pathname.new ENV['OUT_HOME']||ENV['OUT_PATH']||ENV['DOC_PATH']||Rails.root.join('script/deployment/var/apps/cyber-indicators/doc').to_s
    file_name = ENV['FILE_NAME'] || 'cyber-indicators-install.md'

    docs = Dir[doc_home.join('*.md.erb')]
    docs.sort!
    if ENV['CONCAT']

      doc = docs.inject("") do |next_doc,doc|
        next_doc << File.read(doc)
        next_doc << "\n\n"
      end
      renderer = ERB.new(doc)
      result = renderer.result()
      while (result =~ /\n\n\n/)
        result.gsub!(/\n\n\n/,"\n\n")
      end
      while (result =~ /<\\%/)
        result.gsub!(/<\\%/,"<%")
      end
      result.encode(universal_newline: true)
      outfile = out_path.join(file_name)
      File.open(outfile,'w') { |f|
        f.puts result
      }

    else
      docs.each do |doc|
        path_name = Pathname.new doc
        md = path_name.basename('.erb').to_s
        renderer = ERB.new(File.read(doc))
        result = renderer.result()
        while (result =~ /\n\n\n/)
          result.gsub!(/\n\n\n/,"\n\n")
        end
        while (result =~ /<\\%/)
          result.gsub!(/<\\%/,"<%")
        end
        result.encode(universal_newline: true)
        outfile = out_path.join(md)
        File.open(outfile,'w') { |f|
          f.puts result
        }
      end
    end
  end

  task :create => :environment do |t,args|
    make_docs
  end


  task :default => :environment do |t,args|
    ENV['CONCAT']="true" 
    ENV['NOTE']="true" 
    ENV['IMPORTANT']="true" 
    ENV['EXAMPLE']="true"
    ENV['DEVELOPER']=nil
    ENV['CLONE']="true"
    make_docs
  end

  task :troubleshooting => :environment do |t,args|
    ENV['CONCAT']="true" 
    ENV['NOTE']=nil
    ENV['IMPORTANT']=nil 
    ENV['EXAMPLE']=nil
    ENV['CLONE']="true"
    ENV['DEVELOPER']=nil
    ENV['TROUBLESHOOTING']="true"
    ENV['FILE_NAME']='cyber-indicators-troubleshooting.md'
    make_docs
  end

  task :explode => :environment do |t,args|
    ENV['CONCAT']=nil 
    ENV['NOTE']="true"
    ENV['IMPORTANT']="true" 
    ENV['EXAMPLE']="true"
    ENV['CLONE']="true"
    ENV['DEVELOPER']=nil
    ENV['TROUBLESHOOTING']=nil
    ENV['FILE_NAME']='cyber-indicators-troubleshooting.md'
    make_docs
  end  

end
