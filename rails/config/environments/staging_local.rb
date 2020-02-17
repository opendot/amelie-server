require File.expand_path('../staging', __FILE__)
Rails.application.configure do
  config.action_mailer.default_url_options = {:host => "localhost:3001"}
  
end