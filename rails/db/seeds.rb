seed_file = Rails.root.join( 'db', 'seeds', "#{Rails.env.downcase}.rb")
if File.exist?(seed_file)
    load(seed_file)
end
