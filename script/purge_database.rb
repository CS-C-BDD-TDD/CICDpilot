require 'rake'
::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

Rails.application.eager_load!

models=ActiveRecord::Base.descendants

models.each do |m|
  name=m.to_s

  # Do not delete data from the following models
  unless ['Audit',
          'Group',
          'GroupPermission',
          'KillChain',
          'KillChainPhase',
          'Logging::ApiLog',
          'Logging::AuthenticationLog',
          'Logging::Disseminate',
          'Logging::DisseminatedFeed',
          'Logging::DisseminationQueue',
          'Logging::SearchLog',
          'Logging::SystemLog',
          'Organization',
          'Password',
          'PermaTag',
          'Permission',
          'Replication',
          'StixMarkingStructure',
          'SystemTag',
          'User',
          'UserGroup'].include?(name)
    puts name
    name.constantize.delete_all
  end
end

SystemTag.where('is_permanent<>?',true).delete_all
KillChain.where("guid<>'af3e707f-2fb9-49e5-8c37-14026ca0a5ff'").delete_all
KillChainPhase.where("guid not in ('af1016d6-a744-4ed7-ac91-00fe2272185a','445b4827-3cca-42bd-8421-f2e947133c16','79a0e041-9d5f-49bb-ada4-8322622b162d','f706e4e7-53d8-44ef-967f-81535c9db7d0','e1e4e3f7-be3b-4b39-b80a-a593cfd99a4f','d6dc32b9-2538-4951-8733-3cb9ef1daae2','786ca8f9-2d9a-4213-b38e-399af4a2e5d6')").delete_all

# Delete records from these tables as they would have been updated above
for name in [
              'Audit',
              'Logging::ApiLog',
              'Logging::AuthenticationLog',
              'Logging::Disseminate',
              'Logging::DisseminatedFeed',
              'Logging::DisseminationQueue',
              'Logging::SearchLog',
              'Logging::SystemLog'
            ] do
  puts name
  name.constantize.delete_all
end
ActiveRecord::Base.connection.execute("delete from cybox_custom_objects")
CyberIndicators::Application.load_tasks
Rake::Task['weather:acs_set'].invoke
::Sunspot.session = ::Sunspot.session.original_session
Rake::Task['sunspot:solr:reindex'].invoke
