Rails.application.configure do
    # Settings specified here will take precedence over those in config/application.rb.
  
    # In the development environment your application's code is reloaded on
    # every request. This slows down response time but is perfect for development
    # since you don't have to restart the web server when you make code changes.
    config.cache_classes = true
  
    # Eager load code on boot.
    config.eager_load = true
  
    # Show full error reports.
    config.consider_all_requests_local = false
  
    # Enable/disable caching. By default caching is disabled.
    if Rails.root.join('tmp/caching-dev.txt').exist?
      config.action_controller.perform_caching = true
  
      config.cache_store = :memory_store
      config.public_file_server.headers = {
        'Cache-Control' => "public, max-age=#{2.days.seconds.to_i}"
      }
    else
      config.action_controller.perform_caching = false
  
      config.cache_store = :null_store
    end
  
    #Active job adapter
    config.active_job.queue_adapter = :sidekiq
  
    #Action Mailer config
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.perform_caching = false
    config.action_mailer.default_url_options = {:host => "staging.host.it"}
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      :address              => "smtp.gmail.com",
      :port                 => 587,
      :domain               => "gmail.com",
      :user_name            => "your.mail@gmail.com",
      :password             => "yourpassword",
      :authentication       => :plain,
      :enable_starttls_auto => true
    }
  
    # Print deprecation notices to the Rails logger.
    config.active_support.deprecation = :log
  
    # Raise an error on page load if there are pending migrations.
    config.active_record.migration_error = :page_load
  
    #cross request  
    config.action_cable.disable_request_forgery_protection = true
  
    # Raises error for missing translations
    # config.action_view.raise_on_missing_translations = true
  
    # Use an evented file watcher to asynchronously detect changes in source code,
    # routes, locales, etc. This feature depends on the listen gem.
    config.file_watcher = ActiveSupport::EventedFileUpdateChecker
  
    config.logger = Logger.new(STDOUT)
  end
  