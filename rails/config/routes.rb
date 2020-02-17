if Rails.env.ends_with?("remote")
  load(Rails.root.join( 'config', "routes_remote.rb"))
elsif  Rails.env.test?
  # Change routes for test depending on wheteher Docker container is in *_local or *_remote environment
  if ENV["TEST_ROUTES"] == "local"
    load(Rails.root.join( 'config', "routes_local.rb"))
  else
    load(Rails.root.join( 'config', "routes_remote.rb"))
  end
else
  load(Rails.root.join( 'config', "routes_local.rb"))
end
