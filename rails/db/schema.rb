# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20191009134810) do

  create_table "audio_files", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "training_session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "audio_file"
    t.index ["training_session_id"], name: "index_audio_files_on_training_session_id"
  end

  create_table "available_boxes", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "box_id"
    t.string "patient_id"
    t.integer "status", default: 0, null: false
    t.float "progress", limit: 24, default: 0.0, null: false
    t.integer "current_target_id"
    t.string "current_target_name"
    t.integer "current_target_position", default: 0, null: false
    t.integer "targets_count", default: 0, null: false
    t.string "current_exercise_tree_id"
    t.string "current_exercise_tree_name"
    t.integer "current_exercise_tree_conclusions_count"
    t.integer "current_exercise_tree_consecutive_conclusions_required"
    t.integer "target_exercise_tree_position", default: 0, null: false
    t.integer "target_exercise_trees_count", default: 0, null: false
    t.datetime "last_completed_exercise_tree_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_available_boxes_on_deleted_at"
  end

  create_table "available_exercise_trees", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "exercise_tree_id"
    t.string "patient_id"
    t.integer "status", default: 0, null: false
    t.integer "conclusions_count"
    t.integer "consecutive_conclusions_required"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.boolean "force_completed", default: false, null: false
    t.index ["deleted_at"], name: "index_available_exercise_trees_on_deleted_at"
  end

  create_table "available_levels", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "level_id"
    t.string "patient_id"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_available_levels_on_deleted_at"
  end

  create_table "available_targets", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "target_id"
    t.string "patient_id"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_available_targets_on_deleted_at"
  end

  create_table "badges", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "patient_id"
    t.datetime "date"
    t.integer "achievement"
    t.integer "target_id"
    t.string "target_name"
    t.integer "box_id"
    t.string "box_name"
    t.integer "level_id"
    t.string "level_name"
    t.integer "count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_badges_on_patient_id"
  end

  create_table "box_layouts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "box_id"
    t.integer "target_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_box_layouts_on_deleted_at"
  end

  create_table "boxes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.integer "level_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "published", default: true
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_boxes_on_deleted_at"
  end

  create_table "cards", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "label"
    t.integer "level"
    t.string "type"
    t.string "content_id"
    t.string "patient_id"
    t.string "session_event_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "selection_action", default: 0
    t.string "selection_sound"
    t.index ["content_id"], name: "index_cards_on_content_id"
    t.index ["patient_id"], name: "index_cards_on_patient_id"
    t.index ["session_event_id"], name: "index_cards_on_session_event_id"
  end

  create_table "cards_card_tags", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "card_id"
    t.string "card_tag_id"
    t.index ["card_id"], name: "index_cards_card_tags_on_card_id"
    t.index ["card_tag_id"], name: "index_cards_card_tags_on_card_tag_id"
  end

  create_table "contents", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "content"
    t.string "content_thumbnail"
    t.string "filename"
    t.integer "size"
    t.float "duration", limit: 24
  end

  create_table "feedback_pages_feedback_tags", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "feedback_page_id"
    t.string "feedback_tag_id"
    t.index ["feedback_page_id"], name: "index_feedback_pages_feedback_tags_on_feedback_page_id"
    t.index ["feedback_tag_id"], name: "index_feedback_pages_feedback_tags_on_feedback_tag_id"
  end

  create_table "invites", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "mail"
    t.string "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "patient_id"
    t.index ["patient_id"], name: "index_invites_on_patient_id"
    t.index ["user_id"], name: "index_invites_on_user_id"
  end

  create_table "levels", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.integer "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "published", default: true
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_levels_on_deleted_at"
  end

  create_table "notices", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text "message"
    t.boolean "read", default: false
    t.string "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notices_on_user_id"
  end

  create_table "page_layouts", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "page_id"
    t.string "card_id"
    t.float "x_pos", limit: 24
    t.float "y_pos", limit: 24
    t.float "scale", limit: 24
    t.string "next_page_id"
    t.boolean "hidden_link", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.boolean "correct"
    t.boolean "selectable", default: true, null: false
    t.index ["page_id"], name: "index_page_layouts_on_page_id"
  end

  create_table "pages", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "session_event_id"
    t.string "patient_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "ancestry"
    t.integer "ancestry_depth", default: 0
    t.string "background_color"
    t.index ["patient_id"], name: "index_pages_on_patient_id"
    t.index ["session_event_id"], name: "index_pages_on_session_event_id"
  end

  create_table "pages_page_tags", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "page_id"
    t.string "page_tag_id"
    t.index ["page_id"], name: "index_pages_page_tags_on_page_id"
    t.index ["page_tag_id"], name: "index_pages_page_tags_on_page_tag_id"
  end

  create_table "patients", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.string "surname", null: false
    t.date "birthdate", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "region"
    t.string "province"
    t.string "city"
    t.string "mutation"
    t.boolean "disabled"
  end

  create_table "patients_users", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "user_id"
    t.string "patient_id"
    t.index ["patient_id", "user_id"], name: "index_patients_users_on_patient_id_and_user_id", unique: true
    t.index ["patient_id"], name: "index_patients_users_on_patient_id"
    t.index ["user_id"], name: "index_patients_users_on_user_id"
  end

  create_table "preferences", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "num_invites"
    t.integer "user_expiration_days"
    t.text "invite_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "queued_synchronizables", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "synchronizable_id"
    t.string "synchronizable_type"
    t.string "patient_id"
    t.string "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "session_events", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "timestamp", precision: 5
    t.string "training_session_id"
    t.string "page_id"
    t.string "tracker_calibration_parameter_id"
    t.string "card_id"
    t.string "next_page_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tree_id"
    t.index ["card_id"], name: "index_session_events_on_card_id"
    t.index ["next_page_id"], name: "index_session_events_on_next_page_id"
    t.index ["page_id"], name: "index_session_events_on_page_id"
    t.index ["tracker_calibration_parameter_id"], name: "index_tracker_calibration_parameter_id_on_session_events"
    t.index ["training_session_id"], name: "index_session_events_on_training_session_id"
  end

  create_table "synchronizations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "user_id"
    t.string "patient_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "direction"
    t.boolean "success"
    t.boolean "ongoing"
    t.datetime "started_at"
    t.datetime "completed_at"
  end

  create_table "tags", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "tag"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag"], name: "index_tags_on_tag"
  end

  create_table "target_layouts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "exercise_tree_id"
    t.integer "target_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_target_layouts_on_deleted_at"
  end

  create_table "targets", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "published", default: true
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_targets_on_deleted_at"
  end

  create_table "tracker_calibration_parameters", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.float "fixing_radius", limit: 24
    t.integer "fixing_time_ms"
    t.string "patient_id"
    t.string "training_session_id"
    t.string "tracker_calibration_parameter_change_event_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "setting", default: 1
    t.text "transition_matrix"
    t.float "trained_fixation_time", limit: 24
    t.index ["patient_id"], name: "index_tracker_calibration_parameters_on_patient_id"
    t.index ["tracker_calibration_parameter_change_event_id"], name: "index_tracker_calibration_parameter_change_event_id"
    t.index ["training_session_id"], name: "index_tracker_calibration_parameters_on_training_session_id"
  end

  create_table "tracker_raw_data", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "timestamp", precision: 5
    t.float "x_position", limit: 24
    t.float "y_position", limit: 24
    t.string "training_session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["training_session_id"], name: "index_tracker_raw_data_on_training_session_id"
  end

  create_table "training_sessions", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "start_time"
    t.float "duration", limit: 24
    t.integer "screen_resolution_x"
    t.integer "screen_resolution_y"
    t.string "tracker_type"
    t.string "user_id"
    t.string "patient_id"
    t.string "audio_file_id"
    t.string "tracker_calibration_parameter_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["audio_file_id"], name: "index_training_sessions_on_audio_file_id"
    t.index ["patient_id"], name: "index_training_sessions_on_patient_id"
    t.index ["tracker_calibration_parameter_id"], name: "index_training_sessions_on_tracker_calibration_parameter_id"
    t.index ["user_id"], name: "index_training_sessions_on_user_id"
  end

  create_table "trees", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "root_page_id"
    t.string "patient_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.string "user_id"
    t.string "presentation_page_id"
    t.string "strong_feedback_page_id"
    t.index ["patient_id"], name: "index_trees_on_patient_id"
  end

  create_table "user_trees", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "user_id"
    t.string "tree_id"
    t.boolean "favourite"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :string, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "name"
    t.string "email"
    t.string "surname"
    t.date "birthdate"
    t.text "tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.string "organization"
    t.string "role"
    t.text "description"
    t.boolean "allow_password_change", default: false, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "invites", "patients"
  add_foreign_key "invites", "users"
  add_foreign_key "notices", "users"
end
