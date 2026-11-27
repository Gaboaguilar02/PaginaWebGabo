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

ActiveRecord::Schema[8.1].define(version: 2026_11_28_010003) do
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

  create_table "appliance_types", force: :cascade do |t|
    t.string "nombre", null: false
    t.boolean "activo", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nombre"], name: "index_appliance_types_on_nombre", unique: true
  end

  create_table "bonus_payments", force: :cascade do |t|
    t.integer "company_id", null: false
    t.integer "technician_id", null: false
    t.integer "registrado_por_id", null: false
    t.integer "bonus_tier_id"
    t.date "periodo", null: false
    t.string "tier_nombre", null: false
    t.integer "casos_minimos", null: false
    t.integer "casos_resueltos", null: false
    t.decimal "monto", precision: 10, scale: 2, null: false
    t.string "nota"
    t.datetime "pagado_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "porcentaje", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "sueldo_base", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "promedio", precision: 3, scale: 2
    t.index ["bonus_tier_id"], name: "index_bonus_payments_on_bonus_tier_id"
    t.index ["company_id"], name: "index_bonus_payments_on_company_id"
    t.index ["registrado_por_id"], name: "index_bonus_payments_on_registrado_por_id"
    t.index ["technician_id", "periodo"], name: "index_bonus_payments_on_technician_id_and_periodo", unique: true
    t.index ["technician_id"], name: "index_bonus_payments_on_technician_id"
  end

  create_table "bonus_tiers", force: :cascade do |t|
    t.integer "company_id", null: false
    t.string "nombre", null: false
    t.integer "casos_minimos", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "porcentaje", precision: 5, scale: 2, default: "5.0", null: false
    t.index ["company_id", "casos_minimos"], name: "index_bonus_tiers_on_company_id_and_casos_minimos", unique: true
    t.index ["company_id"], name: "index_bonus_tiers_on_company_id"
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
    t.decimal "min_calificacion", precision: 3, scale: 2, default: "4.2", null: false
    t.integer "min_casos_participar", default: 20, null: false
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

  create_table "repair_cases", force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "company_id", null: false
    t.integer "technician_id"
    t.integer "appliance_type_id", null: false
    t.integer "city_id", null: false
    t.text "falla", null: false
    t.string "direccion", null: false
    t.string "status", default: "solicitada", null: false
    t.datetime "resuelta_at"
    t.integer "calificacion"
    t.text "comentario_feedback"
    t.datetime "feedback_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "motivo_rechazo"
    t.text "informe_tecnico"
    t.index ["appliance_type_id"], name: "index_repair_cases_on_appliance_type_id"
    t.index ["city_id"], name: "index_repair_cases_on_city_id"
    t.index ["client_id"], name: "index_repair_cases_on_client_id"
    t.index ["company_id"], name: "index_repair_cases_on_company_id"
    t.index ["status"], name: "index_repair_cases_on_status"
    t.index ["technician_id"], name: "index_repair_cases_on_technician_id"
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
    t.decimal "sueldo_base", precision: 10, scale: 2
    t.index ["cedula"], name: "index_users_on_cedula", unique: true
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bonus_payments", "bonus_tiers"
  add_foreign_key "bonus_payments", "companies"
  add_foreign_key "bonus_payments", "users", column: "registrado_por_id"
  add_foreign_key "bonus_payments", "users", column: "technician_id"
  add_foreign_key "bonus_tiers", "companies"
  add_foreign_key "cities", "provinces"
  add_foreign_key "companies", "cities"
  add_foreign_key "company_appliance_types", "appliance_types"
  add_foreign_key "company_appliance_types", "companies"
  add_foreign_key "repair_cases", "appliance_types"
  add_foreign_key "repair_cases", "cities"
  add_foreign_key "repair_cases", "companies"
  add_foreign_key "repair_cases", "users", column: "client_id"
  add_foreign_key "repair_cases", "users", column: "technician_id"
  add_foreign_key "users", "companies"
end
