class AddMotivoRechazoToRepairCases < ActiveRecord::Migration[8.1]
  def change
    add_column :repair_cases, :motivo_rechazo, :string
  end
end
