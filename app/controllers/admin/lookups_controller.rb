module Admin
  # Alimenta el dropdown dependiente: al elegir una provincia, el formulario
  # pide aquí las ciudades que le pertenecen (JSON).
  class LookupsController < BaseController
    def cities
      ciudades = City.where(province_id: params[:province_id]).order(:nombre).select(:id, :nombre)
      render json: ciudades
    end
  end
end
