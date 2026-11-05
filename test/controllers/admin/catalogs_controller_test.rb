require "test_helper"

# Catálogos de apoyo del administrador: electrodomésticos, provincias y ciudades.
class Admin::CatalogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:admin)
  end

  test "crea un electrodoméstico" do
    assert_difference("ApplianceType.count", 1) do
      post admin_appliance_types_path, params: { appliance_type: { nombre: "Lavavajillas", activo: "1" } }
    end
    assert_redirected_to admin_appliance_types_path
  end

  test "rechaza un electrodoméstico repetido" do
    assert_no_difference("ApplianceType.count") do
      post admin_appliance_types_path, params: { appliance_type: { nombre: "lavadora" } }
    end
    assert_response :unprocessable_entity
  end

  test "no elimina un electrodoméstico en uso" do
    assert_no_difference("ApplianceType.count") { delete admin_appliance_type_path(appliance_types(:lavadora)) }
    assert_redirected_to admin_appliance_types_path
  end

  test "crea una provincia" do
    assert_difference("Province.count", 1) { post admin_provinces_path, params: { province: { nombre: "Loja" } } }
  end

  test "no elimina una provincia con ciudades" do
    assert_no_difference("Province.count") { delete admin_province_path(provinces(:pichincha)) }
  end

  test "crea una ciudad eligiendo su provincia de una lista" do
    assert_difference("City.count", 1) do
      post admin_cities_path, params: { city: { nombre: "Cayambe", province_id: provinces(:pichincha).id } }
    end
    assert_redirected_to admin_cities_path(province_id: provinces(:pichincha).id)
  end

  test "rechaza una ciudad sin provincia o con provincia inexistente" do
    assert_no_difference("City.count") do
      post admin_cities_path, params: { city: { nombre: "Fantasma", province_id: "" } }
      post admin_cities_path, params: { city: { nombre: "Fantasma", province_id: 999_999 } }
    end
  end

  test "filtra las ciudades por provincia" do
    get admin_cities_path(province_id: provinces(:guayas).id)
    assert_response :success
    assert_match "Guayaquil", response.body
    assert_no_match(/Cuenca/, response.body)
  end
end
