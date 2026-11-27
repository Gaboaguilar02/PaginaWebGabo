module Tecnico
  # Todos los controladores del panel del técnico heredan de este.
  # Se exige rol técnico (con empresa) y todo se consulta a través de sus propios casos asignados.
  class BaseController < ApplicationController
    include PeriodoMensual

    before_action :require_tecnico

    private

    def require_tecnico
      unless current_user&.tecnico? && current_user.company
        return redirect_to root_path, alert: "Esta sección es solo para técnicos"
      end

      @company = current_user.company
    end
  end
end
