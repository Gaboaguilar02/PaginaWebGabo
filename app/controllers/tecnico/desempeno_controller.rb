module Tecnico
  # Desempeño del técnico: su posición en el ranking de la empresa, su escalón de bono y su historial de pagos.
  class DesempenoController < BaseController
    def index
      @ranking = MonthlyRanking.new(@company, periodo)
      @mi_fila = @ranking.fila_de(current_user)
      @maximo = [ @ranking.filas.map(&:resueltos).max.to_i, 1 ].max
      @escalones = @company.bonus_tiers.order(:casos_minimos)
      @siguiente_escalon = @company.bonus_tiers.where("casos_minimos > ?", @mi_fila&.resueltos.to_i).order(:casos_minimos).first
      @pagos = current_user.bonos_recibidos.recientes
      @comentarios = current_user.casos_asignados.resueltos.where.not(comentario_feedback: nil)
                                 .where(resuelta_at: @ranking.rango).order(resuelta_at: :desc).limit(5)
    end
  end
end
