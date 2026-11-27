module Tecnico
  class RepairCasesController < BaseController
    before_action :set_repair_case, only: %i[ show salir iniciar resolver evidencias ]

    FILTROS = { "por_atender" => "Por atender", "en_curso" => "En curso", "resueltas" => "Resueltas" }.freeze
    ESTADOS_POR_FILTRO = {
      "por_atender" => %w[ asignada ],
      "en_curso" => %w[ en_camino en_reparacion ],
      "resueltas" => %w[ resuelta ]
    }.freeze

    def index
      @filtro = params[:filtro] if FILTROS.key?(params[:filtro])
      casos = current_user.casos_asignados
      @conteos = casos.group(:status).count
      casos = casos.where(status: ESTADOS_POR_FILTRO[@filtro]) if @filtro
      @repair_cases = casos.includes(:appliance_type, :client, :city).order(updated_at: :desc)
    end

    def show
    end

    def salir
      avanzar(@repair_case.salir!, "Vas en camino al domicilio del cliente")
    end

    def iniciar
      avanzar(@repair_case.iniciar_reparacion!, "Reparación iniciada")
    end

    def resolver
      if @repair_case.resolver!(params[:informe_tecnico])
        redirect_to tecnico_repair_case_path(@repair_case),
                    notice: "¡Caso resuelto! Ya cuenta para tu ranking del mes y el cliente podrá calificarte.", status: :see_other
      else
        mensaje = @repair_case.errors.full_messages.to_sentence.presence || "Este caso no se puede marcar como resuelto todavía"
        redirect_to tecnico_repair_case_path(@repair_case), alert: mensaje, status: :see_other
      end
    end

    # Fotos del trabajo (antes/después, repuestos, etc.) mientras el caso está en atención.
    def evidencias
      archivos = Array(params[:evidencias]).compact_blank
      if !@repair_case.en_atencion?
        redirect_to tecnico_repair_case_path(@repair_case), alert: "Solo se suben evidencias mientras el caso está en atención", status: :see_other
      elsif archivos.empty?
        redirect_to tecnico_repair_case_path(@repair_case), alert: "Elige al menos una imagen", status: :see_other
      elsif @repair_case.evidencias_tecnico.attach(archivos)
        redirect_to tecnico_repair_case_path(@repair_case), notice: "Evidencias subidas", status: :see_other
      else
        # attach devuelve nil si el caso no pasa las validaciones (tipo, tamaño o cantidad de imágenes)
        mensaje = @repair_case.errors.full_messages.to_sentence.presence || "No se pudieron subir las imágenes"
        redirect_to tecnico_repair_case_path(@repair_case), alert: mensaje, status: :see_other
      end
    end

    private

    # Un técnico solo ve y modifica los casos que le asignaron (si no es suyo: 404).
    def set_repair_case
      @repair_case = current_user.casos_asignados.find(params[:id])
    end

    def avanzar(exito, mensaje)
      if exito
        redirect_to tecnico_repair_case_path(@repair_case), notice: mensaje, status: :see_other
      else
        redirect_to tecnico_repair_case_path(@repair_case), alert: "El caso no está en el estado esperado para esta acción", status: :see_other
      end
    end
  end
end
