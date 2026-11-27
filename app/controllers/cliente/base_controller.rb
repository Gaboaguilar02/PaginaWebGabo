module Cliente
  # Todos los controladores de la perspectiva del cliente heredan de este.
  # ApplicationController ya exige sesión (require_login); aquí se exige además el rol cliente.
  class BaseController < ApplicationController
    before_action :require_cliente

    private

    def require_cliente
      return if current_user&.cliente?

      redirect_to root_path, alert: "Esta sección es solo para clientes"
    end
  end
end
