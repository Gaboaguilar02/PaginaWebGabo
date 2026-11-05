class CreateCompanyApplianceTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :company_appliance_types do |t|
      t.references :company, null: false, foreign_key: true
      t.references :appliance_type, null: false, foreign_key: true

      t.timestamps
    end

    add_index :company_appliance_types, [ :company_id, :appliance_type_id ],
              unique: true, name: "index_company_appliance_types_unique"
  end
end
