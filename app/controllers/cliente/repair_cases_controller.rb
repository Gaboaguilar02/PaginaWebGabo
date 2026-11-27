module Cliente
  class RepairCasesController < BaseController
    before_action :set_repair_case, only: %i[ show cancelar calificar ]

    FILTROS = { "activos" => "En curso", "resueltos" => "Resueltos", "cerrados" => "Cancelados / rechazados" }.freeze

    def index
      casos = current_user.solicitudes
      @total = casos.count
      @en_curso = casos.activos.count
      @por_calificar = casos.pendientes_de_calificar.count
      @resueltos = casos.resueltos.count

      @filtro = params[:filtro] if FILTROS.key?(params[:filtro])
      casos = case @filtro
      when "activos" then casos.activos
      when "resueltos" then casos.resueltos
      when "cerrados" then casos.where(status: %w[ cancelada rechazada ])
      else casos
      end
      @repair_cases = casos.includes(:company, :appliance_type, :technician).recientes
    end

    def show
    end

    def new
      @repair_case = current_user.solicitudes.new
      preparar_formulario
    end

    def create
      @repair_case = current_user.solicitudes.new(repair_case_params)
      if @repair_case.save
        redirect_to cliente_repair_case_path(@repair_case), notice: "Solicitud enviada. La empresa la revisará y te asignará un técnico."
      else
        preparar_formulario
        render :new, status: :unprocessable_entity
      end
    end

    def cancelar
      if @repair_case.cancelar!
        redirect_to cliente_repair_case_path(@repair_case), notice: "Solicitud cancelada", status: :see_other
      else
        redirect_to cliente_repair_case_path(@repair_case), alert: "Esta solicitud ya no se puede cancelar", status: :see_other
      end
    end

    def calificar
      if @repair_case.calificar!(params[:calificacion].to_i, params[:comentario_feedback])
        redirect_to cliente_repair_case_path(@repair_case), notice: "¡Gracias por tu calificación!", status: :see_other
      else
        mensaje = @repair_case.errors.full_messages.to_sentence.presence || "Este caso no se puede calificar"
        redirect_to cliente_repair_case_path(@repair_case), alert: mensaje, status: :see_other
      end
    end

    private

    # Un cliente solo ve y modifica sus propios casos (si no es suyo: 404).
    def set_repair_case
      @repair_case = current_user.solicitudes.find(params[:id])
    end

    # Datos para los dropdowns del formulario (electrodoméstico, provincia -> ciudad -> empresa).
    def preparar_formulario
      @appliance_types = ApplianceType.activos.order(:nombre)
      @provinces = Province.order(:nombre)
      @selected_province_id = params[:province_id].presence || @repair_case.city&.province_id
      @cities = @selected_province_id.present? ? City.where(province_id: @selected_province_id).order(:nombre) : City.none
      @companies = Company.disponibles_para(city_id: @repair_case.city_id, appliance_type_id: @repair_case.appliance_type_id)
    end

    def repair_case_params
      params.require(:repair_case).permit(:appliance_type_id, :city_id, :company_id, :falla, :direccion, evidencias: [])
    end
  end
end
