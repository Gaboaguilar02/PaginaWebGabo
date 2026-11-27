class AddInformeTecnicoToRepairCases < ActiveRecord::Migration[8.1]
  def change
    add_column :repair_cases, :informe_tecnico, :text
  end
end
