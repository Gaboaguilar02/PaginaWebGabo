module Empresa
  # Registro de pagos de bono. La plataforma solo deja constancia: no mueve dinero.
  class BonusPaymentsController < BaseController
    def index
      @pagos = @company.bonus_payments.includes(:technician, :registrado_por).recientes
      @total_pagado = @pagos.sum(:monto)
    end

    def create
      tecnico = @company.users.where(role: "tecnico").find(params[:technician_id])
      pago = BonusPayment.registrar(company: @company, technician: tecnico, periodo: periodo, por: current_user, nota: params[:nota])

      if pago.persisted?
        redirect_to empresa_ranking_path(mes: periodo.strftime("%Y-%m")),
                    notice: "Pago registrado: #{tecnico.nombre_completo} · escalón #{pago.tier_nombre} · #{helpers.number_to_currency(pago.monto)}", status: :see_other
      else
        redirect_to empresa_ranking_path(mes: periodo.strftime("%Y-%m")), alert: pago.errors.full_messages.to_sentence, status: :see_other
      end
    end
  end
end
