module Admin
  class ProvincesController < BaseController
    before_action :set_province, only: %i[ edit update destroy ]

    def index
      @provinces = Province.includes(:cities).order(:nombre)
    end

    def new
      @province = Province.new
    end

    def create
      @province = Province.new(province_params)
      if @province.save
        redirect_to admin_provinces_path, notice: "Provincia creada"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @province.update(province_params)
        redirect_to admin_provinces_path, notice: "Provincia actualizada"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @province.destroy
        redirect_to admin_provinces_path, notice: "Provincia eliminada", status: :see_other
      else
        redirect_to admin_provinces_path, alert: @province.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def set_province
      @province = Province.find(params[:id])
    end

    def province_params
      params.require(:province).permit(:nombre)
    end
  end
end
