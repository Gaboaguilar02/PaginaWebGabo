module Tecnico
  class DashboardController < BaseController
    def index
      @ranking = MonthlyRanking.new(@company, periodo)
      @mi_fila = @ranking.fila_de(current_user)
      @siguiente_escalon = siguiente_escalon(@mi_fila&.resueltos.to_i)

      casos = current_user.casos_asignados
      @por_atender = casos.where(status: "asignada").count
      @en_curso = casos.where(status: %w[ en_camino en_reparacion ]).count
      @pendientes_de_calificar = casos.resueltos.where(calificacion: nil).count
      @activos = casos.where(status: RepairCase::EN_ATENCION).includes(:appliance_type, :client, :city).order(:updated_at)
    end

    private

    # Primer escalón que todavía no alcanza (para mostrar "te faltan N casos para Plata").
    def siguiente_escalon(resueltos)
      @company.bonus_tiers.where("casos_minimos > ?", resueltos).order(:casos_minimos).first
    end
  end
end
