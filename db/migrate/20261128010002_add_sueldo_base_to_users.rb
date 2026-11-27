class AddSueldoBaseToUsers < ActiveRecord::Migration[8.1]
  def change
    # Base sobre la que se calcula el bono (porcentaje del sueldo base); lo registra la empresa para cada técnico
    add_column :users, :sueldo_base, :decimal, precision: 10, scale: 2
  end
end
