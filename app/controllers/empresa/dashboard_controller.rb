module Empresa
  class DashboardController < BaseController
    def index
      @ranking = MonthlyRanking.new(@company, periodo)
      casos = @company.repair_cases

      # Indicadores accionables (no dependen del mes elegido)
      @por_aceptar = casos.where(status: "solicitada").count
      @por_asignar = casos.where(status: "aceptada").count
      @en_curso = casos.where(status: %w[ asignada en_camino en_reparacion ]).count

      # Indicadores del mes elegido
      @recibidas_mes = casos.where(created_at: @ranking.rango).count
      @resueltas_mes = @ranking.total_resueltos
      @promedio_mes = @ranking.promedio_general

      @top = @ranking.filas.first(3)
      @pendientes = casos.where(status: %w[ solicitada aceptada ]).includes(:appliance_type, :client).order(:created_at).limit(5)
    end
  end
end
