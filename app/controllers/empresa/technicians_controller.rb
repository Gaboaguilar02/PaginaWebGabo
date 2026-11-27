module Empresa
  # Técnicos de la empresa y su sueldo base (la base del bono en porcentaje).
  class TechniciansController < BaseController
    before_action :set_technician, only: %i[ edit update ]

    def index
      @tecnicos = @company.users.where(role: "tecnico").order(:nombre_completo)
      @ranking = MonthlyRanking.new(@company, Date.current)
      @escalones = @company.bonus_tiers.order(:casos_minimos)
    end

    def edit
      @escalones = @company.bonus_tiers.order(:casos_minimos)
    end

    def update
      if @technician.update(technician_params)
        redirect_to empresa_technicians_path, notice: "Sueldo base de #{@technician.nombre_completo} actualizado", status: :see_other
      else
        @escalones = @company.bonus_tiers.order(:casos_minimos)
        render :edit, status: :unprocessable_entity
      end
    end

    private

    # Solo técnicos de la empresa del usuario (si es de otra: 404).
    def set_technician
      @technician = @company.users.where(role: "tecnico").find(params[:id])
    end

    # La empresa solo puede cambiar el sueldo base; nunca rol, cédula ni contraseña (eso es del administrador).
    def technician_params
      params.require(:user).permit(:sueldo_base)
    end
  end
end
