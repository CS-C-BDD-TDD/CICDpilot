namespace :env do
  task :print => :environment do
    pp ENV
    puts "Environment Configuration:"
    puts({
        "Rails.env" => Rails.env,
        "Rails.configuration.relative_url_root" => Rails.configuration.relative_url_root,
        "Rails.configuration.action_controller.relative_url_root" => Rails.configuration.action_controller.relative_url_root})
  end
end
