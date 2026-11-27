class CreateBonusTiers < ActiveRecord::Migration[8.1]
  def change
    create_table :bonus_tiers do |t|
      t.references :company, null: false, foreign_key: true
      t.string :nombre, null: false
      t.integer :casos_minimos, null: false
      t.decimal :monto, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :bonus_tiers, %i[ company_id casos_minimos ], unique: true
  end
end
