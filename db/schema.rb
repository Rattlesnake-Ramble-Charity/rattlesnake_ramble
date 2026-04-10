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

ActiveRecord::Schema[7.0].define(version: 2026_03_13_180000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at", precision: nil
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "product_images", force: :cascade do |t|
    t.integer "product_id", null: false
    t.string "url", null: false
    t.string "alt_text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["product_id"], name: "index_product_images_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "description", null: false
    t.integer "quantity", null: false
    t.integer "price", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "race_editions", force: :cascade do |t|
    t.integer "race_id", null: false
    t.date "date", null: false
    t.integer "entry_fee", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "slug"
    t.datetime "default_start_time_male", precision: nil
    t.datetime "default_start_time_female", precision: nil
    t.boolean "accepting_entries", default: true
    t.boolean "selling_merchandise", default: false
    t.string "merchandise_description"
    t.string "merchandise_image_file_name"
    t.integer "merchandise_price"
    t.integer "next_male_bib_number"
    t.integer "next_female_bib_number"
    t.integer "next_kids_bib_number"
    t.index ["race_id", "date"], name: "index_race_editions_on_race_id_and_date", unique: true
    t.index ["race_id"], name: "index_race_editions_on_race_id"
    t.index ["slug"], name: "index_race_editions_on_slug", unique: true
  end

  create_table "race_entries", force: :cascade do |t|
    t.integer "race_edition_id", null: false
    t.integer "racer_id", null: false
    t.integer "time"
    t.boolean "paid", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "bib_number"
    t.datetime "scheduled_start_time", precision: nil
    t.integer "predicted_time"
    t.string "merchandise_size"
    t.index ["race_edition_id"], name: "index_race_entries_on_race_edition_id"
    t.index ["racer_id"], name: "index_race_entries_on_racer_id"
  end

  create_table "racers", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.integer "gender"
    t.string "email", null: false
    t.string "city"
    t.string "state"
    t.date "birth_date", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "races", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.text "location"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "slug"
    t.string "short_name"
    t.index ["name"], name: "index_races_on_name", unique: true
    t.index ["slug"], name: "index_races_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "product_images", "products"
  add_foreign_key "race_editions", "races"
  add_foreign_key "race_entries", "race_editions"
  add_foreign_key "race_entries", "racers"
end
