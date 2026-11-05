class CreateApplianceTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :appliance_types do |t|
      t.string :nombre, null: false
      t.boolean :activo, null: false, default: true

      t.timestamps
    end

    add_index :appliance_types, :nombre, unique: true
  end
end
