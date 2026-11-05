module Admin
  class CitiesController < BaseController
    before_action :set_city, only: %i[ edit update destroy ]
    before_action :cargar_provincias, only: %i[ new create edit update ]

    def index
      @province_id = params[:province_id].presence
      @cities = City.includes(:province).order(:nombre)
      @cities = @cities.where(province_id: @province_id) if @province_id
      @provinces = Province.order(:nombre)
    end

    def new
      @city = City.new(province_id: params[:province_id])
    end

    def create
      @city = City.new(city_params)
      if @city.save
        redirect_to admin_cities_path(province_id: @city.province_id), notice: "Ciudad creada"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @city.update(city_params)
        redirect_to admin_cities_path(province_id: @city.province_id), notice: "Ciudad actualizada"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @city.destroy
        redirect_to admin_cities_path(province_id: @city.province_id), notice: "Ciudad eliminada", status: :see_other
      else
        redirect_to admin_cities_path, alert: @city.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def set_city
      @city = City.find(params[:id])
    end

    def cargar_provincias
      @provinces = Province.order(:nombre)
    end

    def city_params
      params.require(:city).permit(:nombre, :province_id)
    end
  end
end
