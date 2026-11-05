module Admin
  class ApplianceTypesController < BaseController
    before_action :set_appliance_type, only: %i[ edit update destroy ]

    def index
      @appliance_types = ApplianceType.order(:nombre)
    end

    def new
      @appliance_type = ApplianceType.new
    end

    def create
      @appliance_type = ApplianceType.new(appliance_type_params)
      if @appliance_type.save
        redirect_to admin_appliance_types_path, notice: "Electrodoméstico agregado al catálogo"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @appliance_type.update(appliance_type_params)
        redirect_to admin_appliance_types_path, notice: "Electrodoméstico actualizado"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @appliance_type.destroy
        redirect_to admin_appliance_types_path, notice: "Electrodoméstico eliminado", status: :see_other
      else
        redirect_to admin_appliance_types_path, alert: @appliance_type.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def set_appliance_type
      @appliance_type = ApplianceType.find(params[:id])
    end

    def appliance_type_params
      params.require(:appliance_type).permit(:nombre, :activo)
    end
  end
end
