class CreateBonusPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :bonus_payments do |t|
      t.references :company, null: false, foreign_key: true
      t.references :technician, null: false, foreign_key: { to_table: :users }
      t.references :registrado_por, null: false, foreign_key: { to_table: :users }
      t.references :bonus_tier, null: true, foreign_key: true
      t.date :periodo, null: false
      # Copia del escalón al momento del pago: si la empresa cambia sus escalones, el historial no se altera.
      t.string :tier_nombre, null: false
      t.integer :casos_minimos, null: false
      t.integer :casos_resueltos, null: false
      t.decimal :monto, precision: 10, scale: 2, null: false
      t.string :nota
      t.datetime :pagado_at, null: false

      t.timestamps
    end

    add_index :bonus_payments, %i[ technician_id periodo ], unique: true
  end
end
