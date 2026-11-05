module Admin
  class CompaniesController < BaseController
    before_action :set_company, only: %i[ show edit update destroy cambiar_estado ]

    def index
      @companies = Company.includes(:appliance_types, city: :province).order(:nombre)
    end

    def show
      @tecnicos = @company.users.order(:nombre_completo)
    end

    def new
      @company = Company.new
      preparar_formulario
    end

    def create
      @company = Company.new(company_params)
      if @company.save
        redirect_to admin_company_path(@company), notice: "Empresa creada correctamente"
      else
        preparar_formulario
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      preparar_formulario
    end

    def update
      if @company.update(company_params)
        redirect_to admin_company_path(@company), notice: "Empresa actualizada correctamente"
      else
        preparar_formulario
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @company.destroy
        redirect_to admin_companies_path, notice: "Empresa eliminada", status: :see_other
      else
        redirect_to admin_companies_path, alert: @company.errors.full_messages.to_sentence, status: :see_other
      end
    end

    # Aprobar / suspender / reactivar una empresa desde el listado
    def cambiar_estado
      nuevo_estado = params[:status].to_s
      if Company::STATUSES.include?(nuevo_estado) && @company.update(status: nuevo_estado)
        redirect_to admin_companies_path, notice: "La empresa #{@company.nombre} ahora está #{@company.status_label.downcase}", status: :see_other
      else
        mensaje = @company.errors.full_messages.to_sentence.presence || "Estado no válido"
        redirect_to admin_companies_path, alert: mensaje, status: :see_other
      end
    end

    private

    def set_company
      @company = Company.find(params[:id])
    end

    # Datos para los dropdowns del formulario (provincia -> ciudad y electrodomésticos).
    def preparar_formulario
      @provinces = Province.order(:nombre)
      @appliance_types = ApplianceType.activos.order(:nombre)
      @selected_province_id = params[:province_id].presence || @company.city&.province_id
      @cities = @selected_province_id.present? ? City.where(province_id: @selected_province_id).order(:nombre) : City.none
    end

    def company_params
      params.require(:company).permit(:nombre, :ruc, :descripcion, :telefono, :direccion, :city_id, :status,
                                      appliance_type_ids: [])
    end
  end
end
