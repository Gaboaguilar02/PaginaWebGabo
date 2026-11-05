require "test_helper"

class Admin::LookupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:admin)
  end

  test "devuelve en JSON solo las ciudades de la provincia elegida" do
    get admin_lookups_cities_path(province_id: provinces(:pichincha).id)
    assert_response :success

    ciudades = response.parsed_body
    assert_equal [ "Quito" ], ciudades.map { |c| c["nombre"] }
    assert_equal [ cities(:quito).id ], ciudades.map { |c| c["id"] }
  end

  test "devuelve una lista vacía si la provincia no existe" do
    get admin_lookups_cities_path(province_id: 999_999)
    assert_response :success
    assert_equal [], response.parsed_body
  end

  test "devuelve una lista vacía si no se indica provincia" do
    get admin_lookups_cities_path
    assert_equal [], response.parsed_body
  end
end
