module Empresa
  # Escalones de bono que define cada empresa (p. ej. Bronce 5 casos, Plata 10, Oro 15).
  class BonusTiersController < BaseController
    before_action :set_tier, only: %i[ edit update destroy ]

    def index
      @escalones = @company.bonus_tiers.order(:casos_minimos)
      @pagos = @company.bonus_payments.includes(:technician).recientes.limit(10)
    end

    def new
      @tier = @company.bonus_tiers.new
    end

    def create
      @tier = @company.bonus_tiers.new(tier_params)
      if @tier.save
        redirect_to empresa_bonus_tiers_path, notice: "Escalón creado"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @tier.update(tier_params)
        redirect_to empresa_bonus_tiers_path, notice: "Escalón actualizado"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @tier.destroy
      redirect_to empresa_bonus_tiers_path, notice: "Escalón eliminado (los pagos ya registrados conservan su historial)", status: :see_other
    end

    private

    def set_tier
      @tier = @company.bonus_tiers.find(params[:id])
    end

    def tier_params
      params.require(:bonus_tier).permit(:nombre, :casos_minimos, :monto)
    end
  end
end
