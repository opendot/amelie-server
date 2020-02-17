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
if User.exists?(id:"testUser")
  puts "Database was already seeded. Aborting."
  return
end

puts ""
puts "TEST SEED"

# Create the default test account

puts ""
puts "Creating default users"
puts "------------------------------------------------------"
user = Researcher.create(id: "testUser", email: "researcher@mail.it", password: "password", password_confirmation: "password", name: "Researcher", surname: "Test")
puts "email: #{user.email}"
puts "password: password"
parent = Parent.create!(id: "testParent", email: "parent@mail.it", password: "password", password_confirmation: "password", name: "Parent", surname: "Test")
puts "email: #{parent.email}"
puts "password: password"
superadmin = Superadmin.create!(id: "testSuperadmin", email: "admin@mail.it", password: "password", password_confirmation: "password", name: "Superadmin", surname: "Test")
puts "email: #{superadmin.email}"
puts "password: password"
puts "------------------------------------------------------"

puts ""

puts ""
puts "Creating default desktop user"
puts "------------------------------------------------------"
DesktopPc.create(id: "dskpc", email: "desktop@pc.it", password: "cppotksed", password_confirmation: "cppotksed", name: "Desktop", surname: "Pc")
puts "email: desktop@pc.it"
puts "password: cppotksed"
puts "------------------------------------------------------"

puts ""

puts "Creating some patients"
puts "------------------------------------------------------"
patients = []
5.times do |i|
  patient = Patient.create!(id: "patient#{i}", name: FFaker::NameIT.first_name, surname: FFaker::NameIT.last_name, birthdate: FFaker::Time.date)
  # Don't add patients to the user, this will be done only by the tests that need it
  patients << patient.id
  TobiiCalibrationParameter.create(id: SecureRandom.uuid(), fixing_radius: 0.05, fixing_time_ms: 600, patient_id: patient.id)
  puts patient.inspect
end
puts "------------------------------------------------------"

puts ""

puts ""
puts "Creating guest user"
puts "------------------------------------------------------"
guest = GuestUser.create!(id: "guestUser", email: "guest@mail.it", password: ENV["GUEST_USER_PASSWORD"], password_confirmation: ENV["GUEST_USER_PASSWORD"], name: "Guest", surname: "Test")
puts "email: #{guest.email}"
puts "------------------------------------------------------"

puts ""

puts "Creating guest patient"
puts "------------------------------------------------------"
guest_patient = Patient.create!(id: "patient_guest", name: FFaker::NameIT.first_name, surname: FFaker::NameIT.last_name, birthdate: FFaker::Time.date)
TobiiCalibrationParameter.create!(id: SecureRandom.uuid(), fixing_radius: 0.05, fixing_time_ms: 600, patient_id: guest_patient.id)
guest.add_patient(guest_patient)
puts guest_patient.inspect
puts "------------------------------------------------------"

puts ""

puts "Creating some card tags"
puts "------------------------------------------------------"
card_tags = []
5.times do |i|
  tag = CardTag.create(id: SecureRandom.uuid(), tag: "Card tag, random: #{SecureRandom.uuid()}")
  card_tags << tag.id
  puts tag.inspect
end
puts "------------------------------------------------------"

puts ""

puts "Creating some page tags"
puts "------------------------------------------------------"
page_tags = []
5.times do |i|
  tag = PageTag.create(id: SecureRandom.uuid(), tag: "Page tag, random: #{SecureRandom.uuid()}")
  page_tags << tag.id
  puts tag.inspect
end
puts "------------------------------------------------------"

puts ""

puts "Creating some pages"
puts "------------------------------------------------------"
puts patients.inspect
2.times do |i|
  page = CustomPage.create(id: "page#{i}", name: "Custom page n. #{i+1}", patient_id: patients[i])
  puts page.inspect
end
puts "------------------------------------------------------"

puts ""

puts "Creating some archived cards"
puts "------------------------------------------------------"
5.times do |i|
  card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/image#{i + 1}.png")))
  card = ArchivedCard.create!(id: "card#{i}", label: "Card n. #{i + 1}", level: 3, patient_id: patients[i], card_tag_ids: card_tags, content_id: card_content.id)
  puts card.inspect
end
puts "------------------------------------------------------"

puts ""

puts "Creating some preset cards"
puts "------------------------------------------------------"
cards_count = Card.all.count
5.times do |i|
  card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/image#{i + 1}.png")))
  card = PresetCard.create!(id: "card#{i + cards_count}", label: "Preset Card n. #{i + 1}", level: 3, card_tag_ids: card_tags, content_id: card_content.id)
  puts card.inspect
end
puts "------------------------------------------------------"

puts ""

puts "Creating some custom cards"
puts "------------------------------------------------------"
cards_count = Card.all.count
5.times do |i|
  card_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/image#{5 - i}.png")))
  card = CustomCard.create!(id: "card#{i + cards_count}", label: "Card n. #{i + 1}", level: 3, patient_id: patients[0], card_tag_ids: card_tags, content_id: card_content.id)
  puts card.inspect
end
puts "------------------------------------------------------"

##
# Cognitive sessions
##

puts "======================================================"
puts "Cognitive Session"

puts "Add feedback pages tags"
puts "------------------------------------------------------"
FeedbackPage::FILTERS.each do |filter|
  tag = FeedbackTag.create(id: filter, tag: filter)
  tag.save!
  puts tag.inspect
end
puts "------------------------------------------------------"

puts ""

puts "Add feedback pages"
puts "------------------------------------------------------"
positive = Tag.find_by_tag("positive")
2.times do |i|
  feedback_page = FeedbackPage.create!(id: SecureRandom.uuid(), name: "Feedback Positive #{i+1}", feedback_tags: [positive])
  feedback_video = Video.create!(id: "positive#{i+1}", content: File.open(File.join(Rails.root, "/public/seed_videos/positive#{i+1}.mp4")))
  card = ArchivedCard.create!(id: "positive#{i+1}", label: "" , level: 3, selection_action: :nothing, content_id: feedback_video.id)

  PageLayout.create!(page: feedback_page, card: card, x_pos: 0.3, y_pos: 0.2, scale: 1)
  feedback_page.set_cards_not_selectable
end


negative = Tag.find_by_tag("negative")
2.times do |i|
  feedback_page = FeedbackPage.create!(id: SecureRandom.uuid(), name: "Feedback Negative #{i+1}", feedback_tags: [negative])
  feedback_video = Video.create!(id: "negative#{i+1}", content: File.open(File.join(Rails.root, "/public/seed_videos/negative#{i+1}.mp4")))
  card = ArchivedCard.create!(id: "negative#{i+1}", label: "" , level: 3, selection_action: :nothing, content_id: feedback_video.id)

  PageLayout.create!(page: feedback_page, card: card, x_pos: 0.3, y_pos: 0.2, scale: 1)
  feedback_page.set_cards_not_selectable
end

strong = Tag.find_by_tag("strong")
1.times do |i|
  feedback_page = FeedbackPage.create!(id: SecureRandom.uuid(), name: "Feedback Strong #{i+1}", feedback_tags: [strong])
  feedback_video = Video.create!(id: "strong#{i+1}", content: File.open(File.join(Rails.root, "/public/seed_videos/strong#{i+1}.mp4")))
  card = ArchivedCard.create!(id: "strong#{i+1}", label: "" , level: 3, selection_action: :nothing, content_id: feedback_video.id)

  PageLayout.create!(page: feedback_page, card: card, x_pos: 0.3, y_pos: 0.2, scale: 1)
  feedback_page.set_cards_not_selectable
end
puts "------------------------------------------------------"

puts ""

puts "Creating some levels"
puts "------------------------------------------------------"
level1 = Level.create!(value: 1, name: "Prerequisiti")
level2 = Level.create!(value: 2, name: "Base")
level3 = Level.create!(value: 3, name: "Avanzato")
puts "------------------------------------------------------"

puts ""

puts "Creating some boxes"
puts "------------------------------------------------------"
box_animals = Box.create!( name: "Animali", level: level1)
box_food = Box.create!( name: "Cibo", level: level1)

box_music = Box.create!( name: "Musica", level: level2)

box_tools = Box.create!( name: "Oggetti", level: level3)
puts "------------------------------------------------------"

puts ""

puts "Creating some targets"
puts "------------------------------------------------------"
target_bear = Target.create!( name: "Orso")
box_animals.add_target(target_bear, 1)
target_cat = Target.create!( name: "Gatto")
box_animals.add_target(target_cat, 2)
target_dog = Target.create!( name: "Cane")
box_animals.add_target(target_dog, 3)

target_pasta = Target.create!( name: "Pasta")
box_food.add_target(target_pasta, 1)
target_water = Target.create!( name: "Acqua")
box_food.add_target(target_water, 2)

target_drum = Target.create!( name: "Tamburo")
box_music.add_target(target_drum, 1)
target_piano = Target.create!( name: "Pianoforte")
box_music.add_target(target_piano, 2)

target_bicycle = Target.create!( name: "Bicicletta")
box_tools.add_target(target_bicycle, 1)
target_feeding_bottle = Target.create!( name: "Biberon")
box_tools.add_target(target_feeding_bottle, 2)
target_hammer = Target.create!( name: "Martello")
box_tools.add_target(target_hammer, 3)

puts "------------------------------------------------------"

puts ""

puts "Creating ExerciseTree"
puts "------------------------------------------------------"
card_tags = []
targets = [
  target_bear, target_cat, target_dog,
  target_pasta, target_water,
  target_drum, target_piano,
  target_bicycle, target_feeding_bottle, target_hammer,
]
names = [
  "teddy_bear", "cat", "dog",
  "pasta", "water",
  "drum", "piano",
  "bicycle", "feeding_bottle", "hammer",
]
targets.length.times do |i|
  target = targets[i]
  name = names[i]

  # Card Tags
  box_card_tag = CardTag.find_or_create_by!(id: target.box.name, tag: target.box.name)
  exercise_card_tag_ids = [ box_card_tag.id, CardTag.create!(id: name, tag: name).id]
  
  3.times do |j|

    # Presentation page
    presentation_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/#{name}.jpg")))
    presentation_card = ArchivedCard.create!(id: SecureRandom.uuid(), label: name, level: 3, card_tag_ids: exercise_card_tag_ids, content_id: presentation_content.id)

    presentation_page = PresentationPage.create!(id: "exercise_#{name}#{j}_presentation", name: name)

    PageLayout.create!(page: presentation_page, card: presentation_card, x_pos: 0.35, y_pos: 0.2, scale: 1)
    presentation_page.set_cards_not_selectable

    # Root page
    target_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/#{name}.jpg")))
    target_card = CognitiveCard.create!(id: SecureRandom.uuid(), label: name, level: 3, card_tag_ids: exercise_card_tag_ids, content_id: target_content.id)

    empty_content = Text.create!(id: SecureRandom.uuid())
    empty_card = CognitiveCard.create!(id: SecureRandom.uuid(), label: "", level: 5, card_tag_ids: exercise_card_tag_ids, content_id: empty_content.id)

    root_page = PresetPage.create!(id: "exercise_#{name}#{j}_root", name: name)

    CognitivePageLayout.create!(page: root_page, card: target_card, correct: true, x_pos: 0.1, y_pos: 0.2, scale: 1)
    CognitivePageLayout.create!(page: root_page, card: empty_card, correct: false, x_pos: 0.7, y_pos: 0.3, scale: 0.5)

    # Exercise
    exercise = ExerciseTree.create!(id: "exercise_#{name}#{j}", name: "#{name.titleize} #{j}", root_page: root_page, presentation_page_id: presentation_page.id, strong_feedback_page: FeedbackPage.strong_random.first)

    # Pages
    prev_page = root_page
    4.times do |k|
      card_good_content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/#{name}.jpg")))
      card_good = CognitiveCard.create!(id: SecureRandom.uuid(), label: name, level: 3, card_tag_ids: exercise_card_tag_ids, content_id: card_good_content.id)

      card_bad_content = GenericImage.create(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/image1.png")))
      card_bad = CognitiveCard.create(id: SecureRandom.uuid(), label: "Card Bad n. #{k + 1}", level: 3, card_tag_ids: exercise_card_tag_ids, content_id: card_bad_content.id)

      page = PresetPage.create!(id: SecureRandom.uuid(), name: "Exercise page n. #{i+2}")

      # Link with previous page
      prev_page.page_layouts.update_all(next_page_id: page.id)
      page.update!(parent_id: prev_page.id)

      CognitivePageLayout.create!(page: page, card: card_good, correct: true, x_pos: 0.1, y_pos: 0.2, scale: 1)
      CognitivePageLayout.create!(page: page, card: card_bad, correct: false, x_pos: 0.6, y_pos: 0.2, scale: 1)

      prev_page = page
    end
    

    target.add_exercise_tree(exercise, j+1)
    puts exercise.inspect
  end
end
puts "------------------------------------------------------"

puts ""

puts "Complete some ExerciseTree"
puts "------------------------------------------------------"
patient = Patient.find(patients[0])
6.times do |i|
  target = targets[i]

  target.exercise_trees.each do |exercise|
    3.times do |j|
      exercise.completed_by patient, true
    end
    puts exercise.available_box_for(patient.id).inspect
  end
end
patient.available_boxes.where.not(last_completed_exercise_tree_at: nil).update_all(last_completed_exercise_tree_at: 3.days.ago)

patient = Patient.find(patients[1])
3.times do |i|
  target = targets[i]

  target.exercise_trees.each do |exercise|
    3.times do |j|
      exercise.completed_by patient, true
    end
    puts exercise.available_box_for(patient.id).inspect
  end
end
patient.available_boxes.where.not(last_completed_exercise_tree_at: nil).update_all(last_completed_exercise_tree_at: 3.days.ago)

patient = Patient.find(patients[2])

target_bear.exercise_trees.limit(3).each do |exercise|
  3.times do |j|
    exercise.completed_by patient, true
  end
  puts exercise.available_box_for(patient.id).inspect
end

target_cat.exercise_trees.limit(1).each do |exercise|
  3.times do |j|
    exercise.completed_by patient, true
  end
  puts exercise.available_box_for(patient.id).inspect
end

target_pasta.exercise_trees.limit(1).each do |exercise|
  3.times do |j|
    exercise.completed_by patient, true
  end
  puts exercise.available_box_for(patient.id).inspect
end

patient.available_boxes.where.not(last_completed_exercise_tree_at: nil).update_all(last_completed_exercise_tree_at: 3.days.ago)

puts "------------------------------------------------------"
