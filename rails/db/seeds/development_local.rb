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
puts "LOCAL SEED"

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
