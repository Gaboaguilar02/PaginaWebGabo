class CreateCities < ActiveRecord::Migration[8.1]
  def change
    create_table :cities do |t|
      t.references :province, null: false, foreign_key: true
      t.string :nombre, null: false

      t.timestamps
    end

    add_index :cities, [ :province_id, :nombre ], unique: true
  end
end
