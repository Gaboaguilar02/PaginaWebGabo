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

ActiveRecord::Schema[8.1].define(version: 2026_11_05_200006) do
  create_table "appliance_types", force: :cascade do |t|
    t.string "nombre", null: false
    t.boolean "activo", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nombre"], name: "index_appliance_types_on_nombre", unique: true
  end

  create_table "cities", force: :cascade do |t|
    t.integer "province_id", null: false
    t.string "nombre", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["province_id", "nombre"], name: "index_cities_on_province_id_and_nombre", unique: true
    t.index ["province_id"], name: "index_cities_on_province_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "nombre", null: false
    t.string "ruc", null: false
    t.text "descripcion"
    t.string "telefono"
    t.string "direccion"
    t.integer "city_id", null: false
    t.string "status", default: "pendiente", null: false
    t.decimal "rating_promedio", precision: 3, scale: 2, default: "0.0", null: false
    t.integer "reviews_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["city_id"], name: "index_companies_on_city_id"
    t.index ["ruc"], name: "index_companies_on_ruc", unique: true
    t.index ["status"], name: "index_companies_on_status"
  end

  create_table "company_appliance_types", force: :cascade do |t|
    t.integer "company_id", null: false
    t.integer "appliance_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appliance_type_id"], name: "index_company_appliance_types_on_appliance_type_id"
    t.index ["company_id", "appliance_type_id"], name: "index_company_appliance_types_unique", unique: true
    t.index ["company_id"], name: "index_company_appliance_types_on_company_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "nombre"
    t.text "descripcion"
    t.decimal "precio"
    t.integer "stock"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "provinces", force: :cascade do |t|
    t.string "nombre", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nombre"], name: "index_provinces_on_nombre", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nombre_completo"
    t.string "cedula"
    t.string "role", default: "cliente", null: false
    t.boolean "activo", default: true, null: false
    t.integer "company_id"
    t.index ["cedula"], name: "index_users_on_cedula", unique: true
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "cities", "provinces"
  add_foreign_key "companies", "cities"
  add_foreign_key "company_appliance_types", "appliance_types"
  add_foreign_key "company_appliance_types", "companies"
  add_foreign_key "users", "companies"
end
