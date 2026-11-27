require "test_helper"

class Cliente::RepairCasesControllerTest < ActionDispatch::IntegrationTest
  PNG = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")

  setup { login_as users(:cliente) }

  def params_validos(**cambios)
    { repair_case: {
      appliance_type_id: appliance_types(:lavadora).id, city_id: cities(:quito).id, company_id: companies(:tecnifrio).id,
      falla: "La lavadora no enciende y huele a quemado.", direccion: "Av. Amazonas N24-15"
    }.merge(cambios) }
  end

  # ---------- Control de acceso
  test "sin sesión se redirige al login" do
    delete logout_path
    [ cliente_root_path, new_cliente_repair_case_path, cliente_repair_case_path(repair_cases(:solicitada)) ].each do |ruta|
      get ruta
      assert_redirected_to login_url, "#{ruta} debería exigir sesión"
    end
    get cliente_lookups_companies_path
    assert_redirected_to login_url
  end

  test "admin, empresa y técnico no entran a la perspectiva del cliente" do
    [ :admin, :empresa, :tecnico ].each do |rol|
      delete logout_path
      login_as users(rol)
      get cliente_root_path
      assert_redirected_to root_url, "#{rol} no debería ver las solicitudes del cliente"
      get new_cliente_repair_case_path
      assert_redirected_to root_url
    end
  end

  test "al iniciar sesión el cliente llega a sus solicitudes" do
    delete logout_path
    post login_path, params: { username: "cliente1", password: LoginHelper::PASSWORD_DE_PRUEBA }
    assert_redirected_to cliente_root_url
  end

  # ---------- Listado y detalle
  test "el listado muestra solo los casos del cliente" do
    get cliente_root_path
    assert_response :success
    assert_select "td", text: "Lavadora"
    assert_select "tr", text: /Pedro Inactivo/, count: 0
    assert_equal 3, css_select("tbody tr").size
  end

  test "el filtro de resueltas solo trae casos resueltos" do
    get cliente_repair_cases_path(filtro: "resueltos")
    assert_response :success
    assert_equal 1, css_select("tbody tr").size
    assert_select "a", text: "Calificar"
  end

  test "el detalle muestra la línea de tiempo y la acción de cancelar solo si aplica" do
    get cliente_repair_case_path(repair_cases(:solicitada))
    assert_response :success
    assert_select ".timeline__step", 6
    assert_select "button", text: "Cancelar solicitud"

    get cliente_repair_case_path(repair_cases(:en_reparacion))
    assert_select "button", text: "Cancelar solicitud", count: 0
  end

  test "un cliente no puede ver ni modificar el caso de otro" do
    ajena = repair_cases(:ajena)
    get cliente_repair_case_path(ajena)
    assert_response :not_found
    patch cancelar_cliente_repair_case_path(ajena)
    assert_response :not_found
    assert_equal "solicitada", ajena.reload.status
  end

  # ---------- Solicitar servicio
  test "el formulario carga" do
    get new_cliente_repair_case_path
    assert_response :success
    assert_select "select[name='repair_case[appliance_type_id]']"
    assert_select "textarea[name='repair_case[falla]']"
  end

  test "crear una solicitud válida la deja como solicitada y a nombre del cliente" do
    assert_difference "RepairCase.count", 1 do
      post cliente_repair_cases_path, params: params_validos
    end
    caso = RepairCase.order(:id).last
    assert_redirected_to cliente_repair_case_url(caso)
    assert_equal users(:cliente), caso.client
    assert_equal "solicitada", caso.status
  end

  test "no se puede forzar cliente, estado ni técnico desde el formulario" do
    post cliente_repair_cases_path, params: params_validos.deep_merge(
      repair_case: { client_id: users(:inactivo).id, status: "resuelta", technician_id: users(:tecnico).id, calificacion: 5 }
    )
    caso = RepairCase.order(:id).last
    assert_equal users(:cliente), caso.client
    assert_equal "solicitada", caso.status
    assert_nil caso.technician
    assert_nil caso.calificacion
  end

  test "se adjuntan evidencias al crear la solicitud" do
    foto = Rack::Test::UploadedFile.new(StringIO.new(PNG), "image/png", original_filename: "dano.png")
    post cliente_repair_cases_path, params: params_validos(evidencias: [ foto ])
    assert_equal 1, RepairCase.order(:id).last.evidencias.count
  end

  test "una empresa que no atiende esa ciudad es rechazada en el servidor" do
    assert_no_difference "RepairCase.count" do
      post cliente_repair_cases_path, params: params_validos(city_id: cities(:cuenca).id)
    end
    assert_response :unprocessable_entity
  end

  test "una empresa suspendida o pendiente no recibe solicitudes" do
    assert_no_difference "RepairCase.count" do
      post cliente_repair_cases_path, params: params_validos(company_id: companies(:hogarfix).id, city_id: cities(:guayaquil).id)
    end
    assert_response :unprocessable_entity
  end

  # ---------- Cancelar y calificar
  test "el cliente cancela una solicitud todavía no iniciada" do
    patch cancelar_cliente_repair_case_path(repair_cases(:solicitada))
    assert_redirected_to cliente_repair_case_path(repair_cases(:solicitada))
    assert_equal "cancelada", repair_cases(:solicitada).reload.status
  end

  test "no se cancela un caso ya en reparación" do
    patch cancelar_cliente_repair_case_path(repair_cases(:en_reparacion))
    assert_equal "en_reparacion", repair_cases(:en_reparacion).reload.status
    assert_equal "Esta solicitud ya no se puede cancelar", flash[:alert]
  end

  test "el cliente califica un caso resuelto" do
    caso = repair_cases(:resuelta_sin_calificar)
    patch calificar_cliente_repair_case_path(caso), params: { calificacion: 5, comentario_feedback: "Excelente" }
    assert_redirected_to cliente_repair_case_path(caso)
    assert_equal 5, caso.reload.calificacion
    assert_equal 1, companies(:tecnifrio).reload.reviews_count
  end

  test "no se califica un caso que sigue en curso" do
    caso = repair_cases(:en_reparacion)
    patch calificar_cliente_repair_case_path(caso), params: { calificacion: 5 }
    assert_nil caso.reload.calificacion
  end

  # ---------- Dropdowns dependientes
  test "el endpoint de empresas devuelve solo las activas de la ciudad que reparan el electrodoméstico" do
    get cliente_lookups_companies_path(city_id: cities(:quito).id, appliance_type_id: appliance_types(:lavadora).id)
    assert_response :success
    assert_equal [ companies(:tecnifrio).id ], response.parsed_body.map { |c| c["id"] }

    get cliente_lookups_companies_path(city_id: cities(:quito).id, appliance_type_id: appliance_types(:secadora).id)
    assert_empty response.parsed_body

    get cliente_lookups_companies_path(city_id: cities(:guayaquil).id, appliance_type_id: appliance_types(:lavadora).id)
    assert_empty response.parsed_body
  end

  test "el endpoint de ciudades devuelve las de la provincia" do
    get cliente_lookups_cities_path(province_id: provinces(:pichincha).id)
    assert_equal [ "Quito" ], response.parsed_body.map { |c| c["nombre"] }
  end
end
