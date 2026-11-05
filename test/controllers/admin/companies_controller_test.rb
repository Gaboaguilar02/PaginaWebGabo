require "test_helper"

class Admin::CompaniesControllerTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:admin)
  end

  def datos_validos(overrides = {})
    { nombre: "Servicios Andinos", ruc: "1791234561001", descripcion: "Línea blanca", telefono: "022222222",
      direccion: "Calle 1", city_id: cities(:quito).id, status: "pendiente",
      appliance_type_ids: [ appliance_types(:lavadora).id ] }.merge(overrides)
  end

  test "crea una empresa con una ciudad elegida del dropdown" do
    assert_difference("Company.count", 1) do
      post admin_companies_path, params: { company: datos_validos(ruc: "0960000140001") }
    end
    empresa = Company.order(:id).last
    assert_redirected_to admin_company_path(empresa)
    assert_equal cities(:quito), empresa.city
    assert_equal [ appliance_types(:lavadora) ], empresa.appliance_types.to_a
  end

  test "el servidor rechaza un RUC inválido aunque el navegador lo haya dejado pasar" do
    assert_no_difference("Company.count") do
      post admin_companies_path, params: { company: datos_validos(ruc: "1790001238001") }
    end
    assert_response :unprocessable_entity
    assert_match "no es un RUC ecuatoriano válido", response.body
  end

  test "rechaza una empresa sin ciudad" do
    assert_no_difference("Company.count") do
      post admin_companies_path, params: { company: datos_validos(city_id: "") }
    end
    assert_response :unprocessable_entity
  end

  test "rechaza una ciudad que no existe (id manipulado)" do
    assert_no_difference("Company.count") do
      post admin_companies_path, params: { company: datos_validos(city_id: 999_999) }
    end
    assert_response :unprocessable_entity
  end

  test "el formulario nuevo trae las provincias y la ciudad deshabilitada" do
    get new_admin_company_path
    assert_response :success
    assert_select "select#province_id option", text: "Pichincha"
    assert_select "select#company_city_id[disabled]"
  end

  test "al editar, el formulario trae preseleccionadas la provincia y la ciudad" do
    get edit_admin_company_path(companies(:tecnifrio))
    assert_response :success
    assert_select "select#province_id option[selected]", text: "Pichincha"
    assert_select "select#company_city_id option[selected]", text: "Quito"
    assert_select "select#company_city_id option", text: "Guayaquil", count: 0
  end

  test "actualiza una empresa" do
    patch admin_company_path(companies(:tecnifrio)), params: { company: { nombre: "TecniFrío Plus" } }
    assert_redirected_to admin_company_path(companies(:tecnifrio))
    assert_equal "TecniFrío Plus", companies(:tecnifrio).reload.nombre
  end

  test "no actualiza con un RUC inválido" do
    patch admin_company_path(companies(:tecnifrio)), params: { company: { ruc: "1111111111111" } }
    assert_response :unprocessable_entity
    assert_equal "1790001237001", companies(:tecnifrio).reload.ruc
  end

  test "aprueba una empresa pendiente que repara algún electrodoméstico" do
    empresa = companies(:hogarfix)
    empresa.appliance_types = [ appliance_types(:secadora) ]

    patch cambiar_estado_admin_company_path(empresa), params: { status: "activa" }
    assert_redirected_to admin_companies_path
    assert_equal "activa", empresa.reload.status
  end

  test "no aprueba una empresa sin electrodomésticos" do
    patch cambiar_estado_admin_company_path(companies(:hogarfix)), params: { status: "activa" }
    assert_redirected_to admin_companies_path
    assert_equal "pendiente", companies(:hogarfix).reload.status
  end

  test "suspende una empresa" do
    patch cambiar_estado_admin_company_path(companies(:tecnifrio)), params: { status: "suspendida" }
    assert_equal "suspendida", companies(:tecnifrio).reload.status
  end

  test "ignora un estado inventado" do
    patch cambiar_estado_admin_company_path(companies(:tecnifrio)), params: { status: "hackeada" }
    assert_equal "activa", companies(:tecnifrio).reload.status
  end

  test "elimina una empresa sin usuarios" do
    assert_difference("Company.count", -1) { delete admin_company_path(companies(:sin_usuarios)) }
    assert_redirected_to admin_companies_path
  end

  test "no elimina una empresa con usuarios" do
    assert_no_difference("Company.count") { delete admin_company_path(companies(:tecnifrio)) }
    assert_redirected_to admin_companies_path
  end

  test "lista y muestra empresas" do
    get admin_companies_path
    assert_response :success
    assert_match "TecniFrío S.A.", response.body

    get admin_company_path(companies(:tecnifrio))
    assert_response :success
  end
end
