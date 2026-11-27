module Empresa
  # Requisitos para participar en el ranking y cobrar bono: calificación mínima y casos mínimos al mes.
  class RequisitosController < BaseController
    def update
      if @company.update(requisitos_params)
        redirect_to empresa_bonus_tiers_path, notice: "Requisitos actualizados. Se aplican al ranking de cada mes al calcularlo.", status: :see_other
      else
        redirect_to empresa_bonus_tiers_path, alert: @company.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def requisitos_params
      params.require(:company).permit(:min_calificacion, :min_casos_participar)
    end
  end
end
