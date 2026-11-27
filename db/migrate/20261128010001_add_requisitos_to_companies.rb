class AddRequisitosToCompanies < ActiveRecord::Migration[8.1]
  def change
    # Requisitos para participar en el ranking y cobrar bono (los define cada empresa)
    add_column :companies, :min_calificacion, :decimal, precision: 3, scale: 2, null: false, default: 4.2
    add_column :companies, :min_casos_participar, :integer, null: false, default: 20
  end
end
