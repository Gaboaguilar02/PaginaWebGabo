module Cliente
  # Alimenta los dropdowns dependientes del formulario de solicitud (JSON).
  class LookupsController < BaseController
    def cities
      ciudades = City.where(province_id: params[:province_id]).order(:nombre).select(:id, :nombre)
      render json: ciudades
    end

    # Empresas activas de la ciudad que reparan el electrodoméstico elegido.
    def companies
      empresas = Company.disponibles_para(city_id: params[:city_id], appliance_type_id: params[:appliance_type_id])
      render json: empresas.map { |empresa| { id: empresa.id, nombre: empresa.etiqueta_con_reputacion } }
    end
  end
end
