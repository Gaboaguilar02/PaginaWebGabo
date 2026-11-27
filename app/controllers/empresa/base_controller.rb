module Empresa
  # Todos los controladores del panel de la empresa heredan de este.
  # ApplicationController ya exige sesión; aquí se exige rol empresa y se fija la empresa del usuario.
  # Todo se consulta a través de @company, así una empresa nunca ve datos de otra.
  class BaseController < ApplicationController
    before_action :require_empresa
    helper_method :periodo, :opciones_de_mes

    private

    def require_empresa
      unless current_user&.empresa? && current_user.company
        return redirect_to root_path, alert: "Esta sección es solo para usuarios de una empresa"
      end

      @company = current_user.company
    end

    # Mes seleccionado (?mes=2026-10). Por defecto el mes actual; nunca uno futuro.
    def periodo
      @periodo ||= begin
        elegido = Date.strptime(params[:mes].to_s, "%Y-%m").beginning_of_month
        [ elegido, Date.current.beginning_of_month ].min
      rescue ArgumentError
        Date.current.beginning_of_month
      end
    end

    # Últimos 12 meses para el filtro de fecha: [["noviembre 2026", "2026-11"], ...]
    def opciones_de_mes
      (0..11).map do |atras|
        mes = Date.current.beginning_of_month - atras.months
        [ "#{I18n.l(mes, format: '%B %Y')}", mes.strftime("%Y-%m") ]
      end
    end
  end
end
