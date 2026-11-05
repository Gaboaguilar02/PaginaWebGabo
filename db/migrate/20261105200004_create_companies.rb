class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string :nombre, null: false
      t.string :ruc, null: false
      t.text :descripcion
      t.string :telefono
      t.string :direccion
      t.references :city, null: false, foreign_key: true
      t.string :status, null: false, default: "pendiente"
      t.decimal :rating_promedio, precision: 3, scale: 2, null: false, default: 0
      t.integer :reviews_count, null: false, default: 0

      t.timestamps
    end

    add_index :companies, :ruc, unique: true
    add_index :companies, :status
  end
end
