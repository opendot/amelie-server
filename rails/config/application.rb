require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Webapp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Load /lib folder, which contains modules
    config.autoload_paths += %W( #{config.root}/lib/modules )

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Configure the time zone
    config.time_zone = "Europe/Rome"

    # Configure the localization language
    config.i18n.available_locales = [:en, :it]
    config.i18n.default_locale = :it
    # Load all the YAML and Ruby files from the locales directory and all nested directories
    # config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

    config.middleware.use Rack::Cors do
      allow do
        origins '*'
        resource '*',
          :headers => :any,
          :expose  => ['access-token', 'expiry', 'token-type', 'uid', 'client', 'Per-Page', 'Total', 'app_version'],
          :methods => [:get, :post, :options, :delete, :put, :patch],
          :max_age => 0
      end
    end

    ApiPagination.configure do |config|
      config.page_header = 'page'
    end

    # The path that will be used to subscribe to the websocket
    config.action_cable.mount_path = '/cable'

    # The default server ip
    $SERVER_IP = ENV['SERVER_IP']

  end
end