class CreateRepairCases < ActiveRecord::Migration[8.1]
  def change
    create_table :repair_cases do |t|
      t.references :client, null: false, foreign_key: { to_table: :users }
      t.references :company, null: false, foreign_key: true
      t.references :technician, null: true, foreign_key: { to_table: :users }
      t.references :appliance_type, null: false, foreign_key: true
      t.references :city, null: false, foreign_key: true

      t.text :falla, null: false
      t.string :direccion, null: false
      t.string :status, null: false, default: "solicitada"
      t.datetime :resuelta_at

      # Feedback del cliente (alimenta la reputación del técnico y de la empresa)
      t.integer :calificacion
      t.text :comentario_feedback
      t.datetime :feedback_at

      t.timestamps
    end

    add_index :repair_cases, :status
  end
end
