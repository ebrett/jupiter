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

ActiveRecord::Schema[8.0].define(version: 2025_07_29_153741) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cloudflare_challenges", force: :cascade do |t|
    t.string "challenge_id", null: false
    t.string "challenge_type", null: false
    t.json "challenge_data"
    t.string "oauth_state", null: false
    t.json "original_params"
    t.string "session_id", null: false
    t.bigint "user_id"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id"], name: "index_cloudflare_challenges_on_challenge_id", unique: true
    t.index ["expires_at"], name: "index_cloudflare_challenges_on_expires_at"
    t.index ["session_id"], name: "index_cloudflare_challenges_on_session_id"
    t.index ["user_id"], name: "index_cloudflare_challenges_on_user_id"
  end

  create_table "expense_categories", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.bigint "parent_id"
    t.string "qb_account_id"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_expense_categories_on_code", unique: true
    t.index ["parent_id"], name: "index_expense_categories_on_parent_id"
  end

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

  create_table "reimbursement_request_events", force: :cascade do |t|
    t.bigint "reimbursement_request_id", null: false
    t.bigint "user_id", null: false
    t.string "event_type", null: false
    t.string "from_status"
    t.string "to_status"
    t.text "notes"
    t.jsonb "event_data", default: {}
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["event_type"], name: "index_reimbursement_request_events_on_event_type"
    t.index ["reimbursement_request_id", "created_at"], name: "idx_events_request_time"
    t.index ["reimbursement_request_id"], name: "index_reimbursement_request_events_on_reimbursement_request_id"
    t.index ["user_id"], name: "index_reimbursement_request_events_on_user_id"
  end

  create_table "reimbursement_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.integer "amount_cents", null: false
    t.string "currency", default: "USD", null: false
    t.date "expense_date", null: false
    t.string "category", null: false
    t.string "status", default: "draft", null: false
    t.datetime "submitted_at", precision: nil
    t.datetime "reviewed_at", precision: nil
    t.datetime "approved_at", precision: nil
    t.datetime "rejected_at", precision: nil
    t.datetime "paid_at", precision: nil
    t.bigint "approved_by_id"
    t.integer "approved_amount_cents"
    t.text "approval_notes"
    t.text "rejection_reason"
    t.string "request_number", null: false
    t.string "priority", default: "normal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_reimbursement_requests_on_approved_by_id"
    t.index ["category"], name: "index_reimbursement_requests_on_category"
    t.index ["expense_date"], name: "index_reimbursement_requests_on_expense_date"
    t.index ["request_number"], name: "index_reimbursement_requests_on_request_number", unique: true
    t.index ["status"], name: "index_reimbursement_requests_on_status"
    t.index ["submitted_at"], name: "index_reimbursement_requests_on_submitted_at"
    t.index ["user_id"], name: "index_reimbursement_requests_on_user_id"
  end

  create_table "requests", force: :cascade do |t|
    t.string "request_type", null: false
    t.string "request_number", null: false
    t.integer "status", default: 0
    t.decimal "amount_requested", precision: 10, scale: 2
    t.string "currency_code", default: "USD"
    t.decimal "amount_usd", precision: 10, scale: 2
    t.decimal "exchange_rate", precision: 10, scale: 6, default: "1.0"
    t.jsonb "form_data", null: false
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["request_number"], name: "index_requests_on_request_number", unique: true
    t.index ["request_type"], name: "index_requests_on_request_type"
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
    t.string "first_name"
    t.string "last_name"
    t.datetime "email_verified_at"
    t.string "verification_token"
    t.datetime "verification_sent_at"
    t.jsonb "nationbuilder_profile_data"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["verification_token"], name: "index_users_on_verification_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cloudflare_challenges", "users"
  add_foreign_key "expense_categories", "expense_categories", column: "parent_id"
  add_foreign_key "feature_flag_assignments", "feature_flags"
  add_foreign_key "feature_flags", "users", column: "created_by_id"
  add_foreign_key "feature_flags", "users", column: "updated_by_id"
  add_foreign_key "nationbuilder_tokens", "users"
  add_foreign_key "reimbursement_request_events", "reimbursement_requests", on_delete: :cascade
  add_foreign_key "reimbursement_request_events", "users"
  add_foreign_key "reimbursement_requests", "users", column: "approved_by_id"
  add_foreign_key "reimbursement_requests", "users", on_delete: :cascade
  add_foreign_key "sessions", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
