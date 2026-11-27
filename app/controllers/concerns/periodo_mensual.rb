# Filtro de fecha por mes (?mes=2026-10) compartido por los paneles de empresa y técnico.
module PeriodoMensual
  extend ActiveSupport::Concern

  included do
    helper_method :periodo, :opciones_de_mes
  end

  private

  # Mes seleccionado. Por defecto el mes actual; nunca uno futuro ni un valor inválido.
  def periodo
    @periodo ||= begin
      elegido = Date.strptime(params[:mes].to_s, "%Y-%m").beginning_of_month
      [ elegido, Date.current.beginning_of_month ].min
    rescue ArgumentError
      Date.current.beginning_of_month
    end
  end

  # Últimos 12 meses para el filtro: [["noviembre 2026", "2026-11"], ...]
  def opciones_de_mes
    (0..11).map do |atras|
      mes = Date.current.beginning_of_month - atras.months
      [ I18n.l(mes, format: "%B %Y"), mes.strftime("%Y-%m") ]
    end
  end
end
