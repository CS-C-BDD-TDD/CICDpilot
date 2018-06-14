source 'https://rubygems.org'
gem 'rails', '~> 4.2.7'
gem 'jquery-rails', '~> 4.0'
gem 'sprockets', '2.12.3'
# jquery-ui-rails set to 5.0 because the angularjs 'requires' between ruby and jruby are different under the 4.x version.  In 5.0, they are the same.
gem 'jquery-ui-rails', "~> 5.0.0"
gem 'uglifier', '>= 1.3.0'
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'bcrypt', '~> 3.1.7'
gem 'pry-rails', group: [:development, :test]
gem 'spring', group: :development
gem 'awesome_print', group: :development
gem 'ipaddress', "~> 0.8.0"
gem 'sunspot_rails' # Search engine
gem 'sunspot_solr','2.2.0',group: :development # Pre-packages solr distribution
gem 'progress_bar'
gem 'acts_as_paranoid'
gem "rabl"
gem "domain_name_validator"
gem "public_suffix", '~>1.4.6' # Used to tell if domain name is valid: .art etc.
gem "domain_name"
gem 'nokogiri' # used to parse XML
gem 'stix', git: 'git@devops-proto-three:/cyber-indicators/stix.git', :tag => 'v0.7.78'
# gem 'stix', path: "~/code/stix"
gem 'net-sftp'
gem 'rufus-scheduler'

platforms :ruby do
  gem 'thin' # web server that allows https and prefix path
  gem 'therubyracer'
  gem 'sqlite3'
  gem 'sqlite3_ar_regexp', '~> 2.2'
  gem 'pg'
end

# JRuby=v9.1.7.0 compatible to Ruby=v2.3
platforms :jruby do
  # gem 'trinidad', group: [:development], :require => nil # web server that allows https and prefix path
  gem 'jruby-jars', '9.1.7.0'
  gem 'therubyrhino'
  gem 'warbler','>= 2.0.0'
  gem 'activerecord-oracle_enhanced-adapter', '1.6.9'
end

gem 'mime-types','2.99' # Required to be 2.99 for jruby
gem 'net-ssh','2.9.2'
gem 'sunspot','2.2.0'
gem 'rsolr','1.0.12'
gem 'brakeman' # security scanning tool.  Should update frequently
gem 'pry-remote'
gem 'colored' # ANSI color output for rake tasks
gem 'random-word', group: [:development, :test]
gem 'rubyzip', '>= 1.2.0'
