module Admin
  class DashboardController < BaseController
    def index
      @empresas_por_estado = Company.group(:status).count
      @total_empresas = Company.count
      @total_tecnicos = User.where(role: "tecnico").count
      @total_clientes = User.where(role: "cliente").count
      @total_electrodomesticos = ApplianceType.activos.count
      @ultimas_empresas = Company.includes(city: :province).order(created_at: :desc).limit(5)
    end
  end
end
