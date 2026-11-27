module Empresa
  class RankingsController < BaseController
    def index
      @ranking = MonthlyRanking.new(@company, periodo)
      @escalones = @company.bonus_tiers.order(:casos_minimos)
      @maximo = [ @ranking.filas.map(&:resueltos).max.to_i, 1 ].max
    end
  end
end
