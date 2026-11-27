module Empresa
  # Todos los controladores del panel de la empresa heredan de este.
  # ApplicationController ya exige sesión; aquí se exige rol empresa y se fija la empresa del usuario.
  # Todo se consulta a través de @company, así una empresa nunca ve datos de otra.
  class BaseController < ApplicationController
    include PeriodoMensual

    before_action :require_empresa

    private

    def require_empresa
      unless current_user&.empresa? && current_user.company
        return redirect_to root_path, alert: "Esta sección es solo para usuarios de una empresa"
      end

      @company = current_user.company
    end
  end
end
