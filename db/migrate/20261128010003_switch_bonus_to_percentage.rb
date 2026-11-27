class SwitchBonusToPercentage < ActiveRecord::Migration[8.1]
  def change
    # Los escalones pasan de un monto fijo a un porcentaje del sueldo base del técnico
    add_column :bonus_tiers, :porcentaje, :decimal, precision: 5, scale: 2, null: false, default: 5
    remove_column :bonus_tiers, :monto, :decimal, precision: 10, scale: 2, null: false, default: 0

    # El pago guarda una copia de todo lo que se usó para calcularlo (el historial no cambia si luego cambian las reglas)
    add_column :bonus_payments, :porcentaje, :decimal, precision: 5, scale: 2, null: false, default: 0
    add_column :bonus_payments, :sueldo_base, :decimal, precision: 10, scale: 2, null: false, default: 0
    add_column :bonus_payments, :promedio, :decimal, precision: 3, scale: 2
  end
end
