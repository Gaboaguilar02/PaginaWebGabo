require "test_helper"

# Toda la administración exige sesión (sin ella se redirige al login) y rol admin (otros roles vuelven al inicio).
class Admin::AccessControlTest < ActionDispatch::IntegrationTest
  RUTAS_ADMIN = %i[
    admin_root_path admin_companies_path new_admin_company_path admin_users_path new_admin_user_path
    admin_appliance_types_path admin_provinces_path admin_cities_path
  ].freeze

  test "sin sesión todas las URLs de administración redirigen al login" do
    RUTAS_ADMIN.each do |ruta|
      get send(ruta)
      assert_redirected_to login_url, "#{ruta} debería exigir sesión"
    end
  end

  test "sin sesión tampoco se puede crear ni borrar por POST/DELETE" do
    assert_no_difference([ "Company.count", "User.count" ]) do
      post admin_companies_path, params: { company: { nombre: "X" } }
      delete admin_user_path(users(:cliente))
    end
    assert_redirected_to login_url
  end

  test "sin sesión el endpoint JSON de ciudades también está protegido" do
    get admin_lookups_cities_path(province_id: provinces(:pichincha).id)
    assert_redirected_to login_url
  end

  test "un cliente, un técnico o una empresa no entran a la administración" do
    [ :cliente, :tecnico, :empresa ].each do |rol|
      login_as users(rol)
      RUTAS_ADMIN.each do |ruta|
        get send(ruta)
        assert_redirected_to root_url, "#{rol} no debería acceder a #{ruta}"
      end
      delete logout_path
    end
  end

  test "un administrador sí accede a todas las secciones" do
    login_as users(:admin)
    RUTAS_ADMIN.each do |ruta|
      get send(ruta)
      assert_response :success, "#{ruta} debería responder 200"
    end
  end
end
