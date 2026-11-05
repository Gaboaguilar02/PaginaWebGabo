module Admin
  # Todos los controladores del módulo de administración heredan de este.
  # ApplicationController ya exige sesión (require_login); aquí se exige además el rol admin.
  class BaseController < ApplicationController
    before_action :require_admin

    private

    def require_admin
      return if current_user&.admin?

      redirect_to root_path, alert: "No tienes permisos para acceder a la administración"
    end
  end
end
