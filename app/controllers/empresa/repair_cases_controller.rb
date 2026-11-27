module Empresa
  class RepairCasesController < BaseController
    before_action :set_repair_case, only: %i[ show aceptar rechazar asignar ]

    FILTROS = {
      "por_aceptar" => "Por aceptar",
      "por_asignar" => "Por asignar",
      "en_curso" => "En curso",
      "resueltas" => "Resueltas",
      "cerradas" => "Rechazadas / canceladas"
    }.freeze

    ESTADOS_POR_FILTRO = {
      "por_aceptar" => %w[ solicitada ],
      "por_asignar" => %w[ aceptada ],
      "en_curso" => %w[ asignada en_camino en_reparacion ],
      "resueltas" => %w[ resuelta ],
      "cerradas" => %w[ rechazada cancelada ]
    }.freeze

    def index
      @filtro = params[:filtro] if FILTROS.key?(params[:filtro])
      casos = @company.repair_cases
      @conteos = casos.group(:status).count
      casos = casos.where(status: ESTADOS_POR_FILTRO[@filtro]) if @filtro
      @repair_cases = casos.includes(:appliance_type, :client, :technician, :city).order(created_at: :desc)
    end

    def show
      cargar_tecnicos
    end

    def aceptar
      if @repair_case.aceptar!
        redirect_to empresa_repair_case_path(@repair_case), notice: "Solicitud aceptada. Ahora asígnale un técnico.", status: :see_other
      else
        redirect_to empresa_repair_case_path(@repair_case), alert: "Esta solicitud ya no se puede aceptar", status: :see_other
      end
    end

    def rechazar
      if @repair_case.rechazar!(params[:motivo_rechazo])
        redirect_to empresa_repair_cases_path, notice: "Solicitud rechazada", status: :see_other
      else
        mensaje = @repair_case.errors.full_messages.to_sentence.presence || "Esta solicitud ya no se puede rechazar"
        redirect_to empresa_repair_case_path(@repair_case), alert: mensaje, status: :see_other
      end
    end

    def asignar
      tecnico = @company.users.activos.where(role: "tecnico").find_by(id: params[:technician_id])
      if tecnico.nil?
        redirect_to empresa_repair_case_path(@repair_case), alert: "Elige un técnico activo de tu empresa", status: :see_other
      elsif @repair_case.asignar!(tecnico)
        redirect_to empresa_repair_case_path(@repair_case), notice: "Caso asignado a #{tecnico.nombre_completo}", status: :see_other
      else
        redirect_to empresa_repair_case_path(@repair_case), alert: "Este caso ya no admite asignación", status: :see_other
      end
    end

    private

    # Solo casos de la empresa del usuario (si es de otra: 404).
    def set_repair_case
      @repair_case = @company.repair_cases.find(params[:id])
    end

    # Técnicos activos con su carga actual, para repartir bien los casos.
    def cargar_tecnicos
      @tecnicos = @company.users.activos.where(role: "tecnico").order(:nombre_completo)
      @carga = @company.repair_cases.where(status: %w[ asignada en_camino en_reparacion ]).group(:technician_id).count
    end
  end
end
