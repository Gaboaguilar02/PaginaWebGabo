require "test_helper"

class Tecnico::AccessControlTest < ActionDispatch::IntegrationTest
  RUTAS = %i[ tecnico_root_path tecnico_repair_cases_path tecnico_desempeno_path ].freeze

  test "sin sesión todo el panel redirige al login" do
    RUTAS.each do |ruta|
      get send(ruta)
      assert_redirected_to login_url, "#{ruta} debería exigir sesión"
    end
    patch salir_tecnico_repair_case_path(repair_cases(:en_reparacion))
    assert_redirected_to login_url
  end

  test "admin, empresa y cliente no entran al panel del técnico" do
    [ :admin, :empresa, :cliente ].each do |rol|
      delete logout_path
      login_as users(rol)
      RUTAS.each do |ruta|
        get send(ruta)
        assert_redirected_to root_url, "#{rol} no debería acceder a #{ruta}"
      end
    end
  end

  test "un técnico entra a todo su panel" do
    login_as users(:tecnico)
    RUTAS.each do |ruta|
      get send(ruta)
      assert_response :success, "#{ruta} debería responder 200"
    end
  end
end

class Tecnico::RepairCasesTest < ActionDispatch::IntegrationTest
  PNG = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")

  setup do
    login_as users(:tecnico)
    @caso = repair_cases(:solicitada)
    @caso.aceptar!
    @caso.asignar!(users(:tecnico))
  end

  def foto = Rack::Test::UploadedFile.new(StringIO.new(PNG), "image/png", original_filename: "trabajo.png")

  test "el listado solo muestra los casos asignados al técnico" do
    get tecnico_repair_cases_path
    assert_response :success
    # solicitada (ahora asignada), en_reparacion y resuelta_sin_calificar son de Juan; "ajena" no tiene técnico
    assert_equal 3, css_select("tbody tr").size

    get tecnico_repair_cases_path(filtro: "por_atender")
    assert_equal 1, css_select("tbody tr").size
  end

  test "no ve ni modifica casos de otro técnico o sin asignar" do
    delete logout_path
    login_as users(:tecnico_carlos)
    get tecnico_repair_case_path(@caso)
    assert_response :not_found
    patch salir_tecnico_repair_case_path(@caso)
    assert_response :not_found
    patch resolver_tecnico_repair_case_path(repair_cases(:en_reparacion)), params: { informe_tecnico: "Intento de resolver ajeno" }
    assert_response :not_found
    assert_equal "en_reparacion", repair_cases(:en_reparacion).reload.status
  end

  test "recorre el servicio: salir, iniciar y resolver con informe" do
    patch salir_tecnico_repair_case_path(@caso)
    assert_equal "en_camino", @caso.reload.status

    patch iniciar_tecnico_repair_case_path(@caso)
    assert_equal "en_reparacion", @caso.reload.status
    assert_nil @caso.resuelta_at

    patch resolver_tecnico_repair_case_path(@caso), params: { informe_tecnico: "Se cambió la bomba de desagüe y se probó un ciclo completo." }
    assert_redirected_to tecnico_repair_case_path(@caso)
    @caso.reload
    assert_equal "resuelta", @caso.status
    assert_not_nil @caso.resuelta_at
    assert_match "bomba de desagüe", @caso.informe_tecnico
  end

  test "no se puede saltar pasos ni repetirlos" do
    patch iniciar_tecnico_repair_case_path(@caso) # todavía está asignada
    assert_equal "asignada", @caso.reload.status
    patch resolver_tecnico_repair_case_path(@caso), params: { informe_tecnico: "Informe suficientemente largo" }
    assert_equal "asignada", @caso.reload.status
    assert_nil @caso.resuelta_at

    patch salir_tecnico_repair_case_path(@caso)
    patch salir_tecnico_repair_case_path(@caso)
    assert_equal "El caso no está en el estado esperado para esta acción", flash[:alert]
    assert_equal "en_camino", @caso.reload.status
  end

  test "resolver exige un informe" do
    caso = repair_cases(:en_reparacion)
    patch resolver_tecnico_repair_case_path(caso), params: { informe_tecnico: "corto" }
    assert_equal "en_reparacion", caso.reload.status
    assert flash[:alert].present?

    patch resolver_tecnico_repair_case_path(caso), params: { informe_tecnico: "" }
    assert_equal "en_reparacion", caso.reload.status
  end

  test "un caso resuelto ya no se puede volver a mover" do
    caso = repair_cases(:resuelta_sin_calificar)
    [ :salir, :iniciar ].each { |accion| patch send("#{accion}_tecnico_repair_case_path", caso) }
    patch resolver_tecnico_repair_case_path(caso), params: { informe_tecnico: "Otro informe cualquiera aquí" }
    assert_equal "resuelta", caso.reload.status
    assert_nil caso.informe_tecnico
  end

  test "sube evidencias mientras el caso está en atención" do
    assert_difference -> { @caso.reload.evidencias_tecnico.count }, 1 do
      post evidencias_tecnico_repair_case_path(@caso), params: { evidencias: [ foto ] }
    end
    assert_redirected_to tecnico_repair_case_path(@caso)
    assert_equal "Evidencias subidas", flash[:notice]
  end

  test "rechaza evidencias que no son imágenes" do
    pdf = Rack::Test::UploadedFile.new(StringIO.new("%PDF-1.4"), "application/pdf", original_filename: "informe.pdf")
    assert_no_difference -> { @caso.reload.evidencias_tecnico.count } do
      post evidencias_tecnico_repair_case_path(@caso), params: { evidencias: [ pdf ] }
    end
    assert flash[:alert].present?
  end

  test "no sube evidencias sin archivos ni en un caso ya resuelto" do
    post evidencias_tecnico_repair_case_path(@caso)
    assert_equal "Elige al menos una imagen", flash[:alert]

    cerrado = repair_cases(:resuelta_sin_calificar)
    assert_no_difference -> { cerrado.reload.evidencias_tecnico.count } do
      post evidencias_tecnico_repair_case_path(cerrado), params: { evidencias: [ foto ] }
    end
  end

  test "el detalle ofrece la acción que corresponde a cada estado" do
    get tecnico_repair_case_path(@caso)
    assert_select "button, input[type=submit]", text: /Salir hacia el domicilio/

    @caso.salir!
    get tecnico_repair_case_path(@caso)
    assert_select "button, input[type=submit]", text: /iniciar reparación/

    @caso.iniciar_reparacion!
    get tecnico_repair_case_path(@caso)
    assert_select "input[type=submit][value='Marcar como resuelto']"
    assert_select "textarea[name=informe_tecnico]"

    get tecnico_repair_case_path(repair_cases(:resuelta_sin_calificar))
    assert_select "textarea[name=informe_tecnico]", count: 0
  end
end

class Tecnico::DesempenoTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:tecnico)
    crear_escalones(companies(:tecnifrio))
    resolver_casos(users(:tecnico), mes_actual, 3)
    resolver_casos(users(:tecnico_carlos), mes_actual, 6)
  end

  test "el panel muestra mi posición y cuánto falta para el siguiente escalón" do
    get tecnico_root_path
    assert_response :success
    assert_select ".stat__value", text: "#2"
    assert_match "faltan 2 casos", response.body # 3 de 5 para Bronce
  end

  test "el desempeño lista el ranking de la empresa y me marca" do
    get tecnico_desempeno_path
    assert_response :success
    assert_equal 2, css_select(".pos").size # una medalla de posición por técnico en el ranking
    assert_select "tr.row--me", text: /Juan Pérez/
  end

  test "con el escalón alcanzado muestra el bono; en un mes cerrado, también los pagos recibidos" do
    resolver_casos(users(:tecnico), mes_anterior, 11)
    BonusPayment.registrar(company: companies(:tecnifrio), technician: users(:tecnico), periodo: mes_anterior, por: users(:empresa))

    get tecnico_desempeno_path(mes: mes_anterior.strftime("%Y-%m"))
    assert_response :success
    assert_match "$60,00", response.body
    assert_select "td", text: "Plata"
  end

  test "solo ve sus propios pagos" do
    resolver_casos(users(:tecnico_carlos), mes_anterior, 5)
    BonusPayment.registrar(company: companies(:tecnifrio), technician: users(:tecnico_carlos), periodo: mes_anterior, por: users(:empresa))
    get tecnico_desempeno_path
    assert_match "Todavía no tienes bonos registrados", response.body
  end
end
