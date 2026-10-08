class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :nombre
      t.text :descripcion
      t.decimal :precio
      t.integer :stock

      t.timestamps
    end
  end
end
