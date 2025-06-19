# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_06_18_074922) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "feature_flag_assignments", force: :cascade do |t|
    t.bigint "feature_flag_id", null: false
    t.string "assignable_type", null: false
    t.bigint "assignable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignable_type", "assignable_id"], name: "idx_on_assignable_type_assignable_id_7b2ecc96c8"
    t.index ["assignable_type", "assignable_id"], name: "index_feature_flag_assignments_on_assignable"
    t.index ["feature_flag_id", "assignable_type", "assignable_id"], name: "index_feature_flag_assignments_unique", unique: true
    t.index ["feature_flag_id"], name: "index_feature_flag_assignments_on_feature_flag_id"
  end

  create_table "feature_flags", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.boolean "enabled", default: false, null: false
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_feature_flags_on_created_by_id"
    t.index ["name"], name: "index_feature_flags_on_name", unique: true
    t.index ["updated_by_id"], name: "index_feature_flags_on_updated_by_id"
  end

  create_table "nationbuilder_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "access_token"
    t.string "refresh_token"
    t.datetime "expires_at"
    t.string "scope"
    t.jsonb "raw_response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "rotated_at"
    t.integer "version"
    t.index ["user_id"], name: "index_nationbuilder_tokens_on_user_id"
  end

  create_table "rails_sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_rails_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_rails_sessions_on_updated_at"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "remember_me", default: false, null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "setup_wizard_steps", force: :cascade do |t|
    t.bigint "setup_wizard_id", null: false
    t.string "name", null: false
    t.string "status", default: "pending", null: false
    t.text "error_message"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["setup_wizard_id", "name"], name: "index_setup_wizard_steps_on_setup_wizard_id_and_name", unique: true
    t.index ["setup_wizard_id"], name: "index_setup_wizard_steps_on_setup_wizard_id"
  end

  create_table "setup_wizards", force: :cascade do |t|
    t.datetime "completed_at"
    t.string "current_step", null: false
    t.jsonb "nationbuilder_config", default: {}, null: false
    t.jsonb "admin_users", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completed_at"], name: "index_setup_wizards_on_completed_at"
    t.index ["current_step"], name: "index_setup_wizards_on_current_step"
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nationbuilder_uid"
    t.string "first_name"
    t.string "last_name"
    t.datetime "email_verified_at"
    t.string "verification_token"
    t.datetime "verification_sent_at"
    t.jsonb "nationbuilder_profile_data"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["nationbuilder_uid"], name: "index_users_on_nationbuilder_uid", unique: true
    t.index ["verification_token"], name: "index_users_on_verification_token", unique: true
  end

  add_foreign_key "feature_flag_assignments", "feature_flags"
  add_foreign_key "feature_flags", "users", column: "created_by_id"
  add_foreign_key "feature_flags", "users", column: "updated_by_id"
  add_foreign_key "nationbuilder_tokens", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "setup_wizard_steps", "setup_wizards"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
