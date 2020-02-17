# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# NOTE: since ids are hardcoded the seeder can be used only once. This is useful for test purposes.

require 'ffaker'

# Stop if seed has already been done
if User.exists?(id:"guestUser")
  puts "Database was already seeded. Aborting."
  return
end

puts ""
puts "STAGING LOCAL SEED"

puts ""
puts "Creating guest user and guest patient"
puts "------------------------------------------------------"
guest = GuestUser.create!(id: "guestUser", email: "guest@mail.it", password: ENV["GUEST_USER_PASSWORD"], password_confirmation: ENV["GUEST_USER_PASSWORD"], name: "Guest", surname: I18n.t("user.generic"))
patient_guest = Patient.create!(id: "guestPatient", name: "Guest", surname: I18n.t("patient.generic"), birthdate: DateTime.now)
TobiiCalibrationParameter.create!(id: SecureRandom.uuid(), fixing_radius: 0.05, fixing_time_ms: 600, patient_id: patient_guest.id)
guest.add_patient(patient_guest)
puts "email: #{guest.email}"

puts ""

puts ""
puts "Creating default desktop user"
puts "------------------------------------------------------"
DesktopPc.create(id: "dskpc", email: "desktop@pc.it", password: ENV["DESKTOP_PC_USER_PASSWORD"], password_confirmation: ENV["DESKTOP_PC_USER_PASSWORD"], name: "Desktop", surname: "Pc")
puts "email: desktop@pc.it"
puts "------------------------------------------------------"


# Users are retrieved from the online server
puts "Creating some card tags"
puts "------------------------------------------------------"
card_tags = []
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "acqua")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "biscotti")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "bolle")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "brioche")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "carne")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "cioccolato")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "coccodrillo")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "formaggio")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "frutta")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "fruttina")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "ilcaffedellapeppina")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "ipad")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "latte")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "libro")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "mare")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "mashaeorso")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "merendina")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "minestrone")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "montagna")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "nellavecchiafattoria")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "palloncini")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "parcogiochi")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "pasta")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "peppapig")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "pesce")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "pianola")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "piscina")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "pizza")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "prosciutto")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "pupazzo")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "scuola")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "strada")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "succo")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "torta")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "tv")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "verdure")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "wc")
card_tags << tag.id
puts tag.inspect
tag = CardTag.create!(id: SecureRandom.uuid(), tag: "yogurt")
card_tags << tag.id
puts tag.inspect
puts "------------------------------------------------------"

puts ""



puts "Creating some preset cards"
puts "------------------------------------------------------"

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/acqua.jpg")))
card = PresetCard.create!(id: "acqua", label: "acqua", level: 3, card_tag_ids: [CardTag.find_by(tag: "acqua").id],content_id: card_content.id)

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/biscotti.jpg")))
card = PresetCard.create!(id: "biscotti", label: "biscotti", level: 3, card_tag_ids: [CardTag.find_by(tag: "biscotti").id],content_id: card_content.id)

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/bolle.png")))
card = PresetCard.create!(id: "bolle", label: "bolle", level: 3, card_tag_ids: [CardTag.find_by(tag: "bolle").id],content_id: card_content.id)

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/brioche.jpg")))
card = PresetCard.create!(id: "brioche", label: "brioche", level: 3, card_tag_ids: [CardTag.find_by(tag: "brioche").id],content_id: card_content.id)

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/carne.jpg")))
card = PresetCard.create!(id: "carne", label: "carne", level: 3, card_tag_ids: [CardTag.find_by(tag: "carne").id],content_id: card_content.id)

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/cioccolato.jpg")))
card = PresetCard.create!(id: "cioccolato", label: "cioccolato", level: 3, card_tag_ids: [CardTag.find_by(tag: "cioccolato").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/coccodrillo.jpg")))
card = PresetCard.create!(id: "coccodrillo", label: "coccodrillo", level: 3, card_tag_ids: [CardTag.find_by(tag: "coccodrillo").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect


card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/formaggio.jpg")))
card = PresetCard.create!(id: "formaggio", label: "formaggio", level: 3, card_tag_ids: [CardTag.find_by(tag: "formaggio").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/frutta.jpg")))
card = PresetCard.create!(id: "frutta", label: "frutta", level: 3, card_tag_ids: [CardTag.find_by(tag: "frutta").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/fruttina.png")))
card = PresetCard.create!(id: "fruttina", label: "fruttina", level: 3, card_tag_ids: [CardTag.find_by(tag: "fruttina").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/il_caffe_della_peppina.jpg")))
card = PresetCard.create!(id: "il_caffe_della_peppina", label: "il caffé della peppina", level: 3, card_tag_ids: [CardTag.find_by(tag: "ilcaffedellapeppina").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/ipad.jpg")))
card = PresetCard.create!(id: "ipad", label: "ipad", level: 3, card_tag_ids: [CardTag.find_by(tag: "ipad").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/latte.jpg")))
card = PresetCard.create!(id: "latte", label: "latte", level: 3, card_tag_ids: [CardTag.find_by(tag: "latte").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/libro.jpg")))
card = PresetCard.create!(id: "libro", label: "libro", level: 3, card_tag_ids: [CardTag.find_by(tag: "libro").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/mare.jpg")))
card = PresetCard.create!(id: "mare", label: "mare", level: 3, card_tag_ids: [CardTag.find_by(tag: "mare").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/masha_e_orso.jpg")))
card = PresetCard.create!(id: "masha_e_orso", label: "masha e orso", level: 3, card_tag_ids: [CardTag.find_by(tag: "mashaeorso").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect


card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/merendina.jpg")))
card = PresetCard.create!(id: "merendina", label: "merendina", level: 3, card_tag_ids: [CardTag.find_by(tag: "merendina").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/minestrone.jpg")))
card = PresetCard.create!(id: "minestrone", label: "minestrone", level: 3, card_tag_ids: [CardTag.find_by(tag: "minestrone").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/montagna.jpg")))
card = PresetCard.create!(id: "montagna", label: "montagna", level: 3, card_tag_ids: [CardTag.find_by(tag: "montagna").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/nella_vecchia_fattoria.jpg")))
card = PresetCard.create!(id: "nella_vecchia_fattoria", label: "nella vecchia fattoria", level: 3, card_tag_ids: [CardTag.find_by(tag: "nellavecchiafattoria").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/palloncini.jpg")))
card = PresetCard.create!(id: "palloncini", label: "palloncini", level: 3, card_tag_ids: [CardTag.find_by(tag: "palloncini").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/parco_giochi.png")))
card = PresetCard.create!(id: "parco_giochi", label: "parco giochi", level: 3, card_tag_ids: [CardTag.find_by(tag: "parcogiochi").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/pasta.jpg")))
card = PresetCard.create!(id: "pasta", label: "pasta", level: 3, card_tag_ids: [CardTag.find_by(tag: "pasta").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/peppapig.jpg")))
card = PresetCard.create!(id: "peppapig", label: "peppapig", level: 3, card_tag_ids: [CardTag.find_by(tag: "peppapig").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/pesce.jpg")))
card = PresetCard.create!(id: "pesce", label: "pesce", level: 3, card_tag_ids: [CardTag.find_by(tag: "pesce").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/pianola.jpg")))
card = PresetCard.create!(id: "pianola", label: "pianola", level: 3, card_tag_ids: [CardTag.find_by(tag: "pianola").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/piscina.jpg")))
card = PresetCard.create!(id: "piscina", label: "piscina", level: 3, card_tag_ids: [CardTag.find_by(tag: "piscina").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/pizza.jpg")))
card = PresetCard.create!(id: "pizza", label: "pizza", level: 3, card_tag_ids: [CardTag.find_by(tag: "pizza").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/prosciutto.jpg")))
card = PresetCard.create!(id: "prosciutto", label: "prosciutto", level: 3, card_tag_ids: [CardTag.find_by(tag: "prosciutto").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/pupazzo.jpg")))
card = PresetCard.create!(id: "pupazzo", label: "pupazzo", level: 3, card_tag_ids: [CardTag.find_by(tag: "pupazzo").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/scuola.jpg")))
card = PresetCard.create!(id: "scuola", label: "scuola", level: 3, card_tag_ids: [CardTag.find_by(tag: "scuola").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/strada.jpg")))
card = PresetCard.create!(id: "strada", label: "strada", level: 3, card_tag_ids: [CardTag.find_by(tag: "strada").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/succo.jpg")))
card = PresetCard.create!(id: "succo", label: "succo", level: 3, card_tag_ids: [CardTag.find_by(tag: "succo").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/torta.jpg")))
card = PresetCard.create!(id: "torta", label: "torta", level: 3, card_tag_ids: [CardTag.find_by(tag: "torta").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/tv.jpg")))
card = PresetCard.create!(id: "tv", label: "tv", level: 3, card_tag_ids: [CardTag.find_by(tag: "tv").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/verdure.jpg")))
card = PresetCard.create!(id: "verdure", label: "verdure", level: 3, card_tag_ids: [CardTag.find_by(tag: "verdure").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/wc.png")))
card = PresetCard.create!(id: "wc", label: "wc", level: 3, card_tag_ids: [CardTag.find_by(tag: "wc").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect

card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/yogurt.jpg")))
card = PresetCard.create!(id: "yogurt", label: "yogurt", level: 3, card_tag_ids: [CardTag.find_by(tag: "yogurt").id],content_id: card_content.id)
#card.content = card_content

puts card.inspect
