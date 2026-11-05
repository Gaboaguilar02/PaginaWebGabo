class CreateProvinces < ActiveRecord::Migration[8.1]
  def change
    create_table :provinces do |t|
      t.string :nombre, null: false

      t.timestamps
    end

    add_index :provinces, :nombre, unique: true
  end
end
