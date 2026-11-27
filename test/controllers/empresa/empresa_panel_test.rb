require "test_helper"

# Panel de la empresa: acceso, solicitudes, ranking, escalones y pagos.
class Empresa::AccessControlTest < ActionDispatch::IntegrationTest
  RUTAS = %i[
    empresa_root_path empresa_repair_cases_path empresa_ranking_path empresa_bonus_tiers_path
    new_empresa_bonus_tier_path empresa_bonus_payments_path empresa_technicians_path
  ].freeze

  test "sin sesión todo el panel redirige al login" do
    RUTAS.each do |ruta|
      get send(ruta)
      assert_redirected_to login_url, "#{ruta} debería exigir sesión"
    end
  end

  test "sin sesión no se puede aceptar ni crear escalones ni pagos" do
    patch aceptar_empresa_repair_case_path(repair_cases(:solicitada))
    assert_redirected_to login_url
    assert_no_difference([ "BonusTier.count", "BonusPayment.count" ]) do
      post empresa_bonus_tiers_path, params: { bonus_tier: { nombre: "X", casos_minimos: 1, porcentaje: 1 } }
      post empresa_bonus_payments_path, params: { technician_id: users(:tecnico).id }
    end
  end

  test "admin, técnico y cliente no entran al panel de la empresa" do
    [ :admin, :tecnico, :cliente ].each do |rol|
      delete logout_path
      login_as users(rol)
      RUTAS.each do |ruta|
        get send(ruta)
        assert_redirected_to root_url, "#{rol} no debería acceder a #{ruta}"
      end
    end
  end

  test "un usuario de empresa entra a todo el panel" do
    login_as users(:empresa)
    RUTAS.each do |ruta|
      get send(ruta)
      assert_response :success, "#{ruta} debería responder 200"
    end
  end

  test "al iniciar sesión la empresa llega a su panel" do
    post login_path, params: { username: "empresa1", password: LoginHelper::PASSWORD_DE_PRUEBA }
    assert_redirected_to empresa_root_url
  end
end

class Empresa::DashboardTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:empresa)
    crear_escalones(companies(:tecnifrio))
  end

  test "muestra indicadores y mejores técnicos del mes" do
    resolver_casos(users(:tecnico), mes_actual, 6)
    get empresa_root_path
    assert_response :success
    assert_select "h1", text: "TecniFrío S.A."
    assert_select ".stat__label", text: "Por aceptar"
    assert_select "td", text: "Juan Pérez"
  end

  test "un mes mal escrito o futuro cae en el mes actual" do
    get empresa_root_path(mes: "basura")
    assert_response :success
    get empresa_root_path(mes: "2099-01")
    assert_response :success
  end
end

class Empresa::RepairCasesTest < ActionDispatch::IntegrationTest
  setup { login_as users(:empresa) }

  test "el listado solo trae casos de la empresa y filtra por estado" do
    get empresa_repair_cases_path
    assert_response :success
    assert_equal 4, css_select("tbody tr").size # solicitada, en_reparacion, resuelta y ajena (todas de TecniFrío)

    get empresa_repair_cases_path(filtro: "por_aceptar")
    assert_equal 2, css_select("tbody tr").size
  end

  test "no ve ni modifica casos de otra empresa" do
    otro = repair_cases(:de_otra_empresa)
    get empresa_repair_case_path(otro)
    assert_response :not_found
    patch aceptar_empresa_repair_case_path(otro)
    assert_response :not_found
    assert_equal "solicitada", otro.reload.status
  end

  test "acepta una solicitud nueva" do
    caso = repair_cases(:solicitada)
    patch aceptar_empresa_repair_case_path(caso)
    assert_redirected_to empresa_repair_case_path(caso)
    assert_equal "aceptada", caso.reload.status
  end

  test "no acepta dos veces ni una que ya avanzó" do
    patch aceptar_empresa_repair_case_path(repair_cases(:en_reparacion))
    assert_equal "en_reparacion", repair_cases(:en_reparacion).reload.status
    assert_equal "Esta solicitud ya no se puede aceptar", flash[:alert]
  end

  test "rechaza con motivo y el cliente lo ve" do
    caso = repair_cases(:solicitada)
    patch rechazar_empresa_repair_case_path(caso), params: { motivo_rechazo: "No cubrimos esa zona" }
    assert_redirected_to empresa_repair_cases_path
    caso.reload
    assert_equal "rechazada", caso.status
    assert_equal "No cubrimos esa zona", caso.motivo_rechazo

    delete logout_path
    login_as users(:cliente)
    get cliente_repair_case_path(caso)
    assert_match "No cubrimos esa zona", response.body
  end

  test "rechazar exige un motivo" do
    caso = repair_cases(:solicitada)
    patch rechazar_empresa_repair_case_path(caso), params: { motivo_rechazo: "  " }
    assert_equal "solicitada", caso.reload.status
    assert flash[:alert].present?
  end

  test "asigna un técnico a un caso aceptado" do
    caso = repair_cases(:solicitada)
    caso.aceptar!
    patch asignar_empresa_repair_case_path(caso), params: { technician_id: users(:tecnico_carlos).id }
    assert_redirected_to empresa_repair_case_path(caso)
    caso.reload
    assert_equal "asignada", caso.status
    assert_equal users(:tecnico_carlos), caso.technician
  end

  test "puede reasignar mientras el técnico no haya salido" do
    caso = repair_cases(:solicitada)
    caso.aceptar!
    caso.asignar!(users(:tecnico))
    patch asignar_empresa_repair_case_path(caso), params: { technician_id: users(:tecnico_carlos).id }
    assert_equal users(:tecnico_carlos), caso.reload.technician
  end

  test "no asigna un caso que aún no fue aceptado" do
    caso = repair_cases(:solicitada)
    patch asignar_empresa_repair_case_path(caso), params: { technician_id: users(:tecnico).id }
    assert_equal "solicitada", caso.reload.status
    assert_nil caso.technician
  end

  test "no asigna a alguien que no es técnico activo de la empresa" do
    caso = repair_cases(:solicitada)
    caso.aceptar!
    [ users(:cliente), users(:empresa), users(:admin) ].each do |otro|
      patch asignar_empresa_repair_case_path(caso), params: { technician_id: otro.id }
      assert_equal "aceptada", caso.reload.status
    end
    users(:tecnico_carlos).update!(activo: false)
    patch asignar_empresa_repair_case_path(caso), params: { technician_id: users(:tecnico_carlos).id }
    assert_equal "aceptada", caso.reload.status
  end

  test "el detalle ofrece las acciones según el estado" do
    get empresa_repair_case_path(repair_cases(:solicitada))
    assert_select "button, input[type=submit]", text: /Aceptar solicitud/
    assert_select "input[type=submit][value=Rechazar]"

    caso = repair_cases(:solicitada)
    caso.aceptar!
    get empresa_repair_case_path(caso)
    assert_select "select[name=technician_id]"

    get empresa_repair_case_path(repair_cases(:resuelta_sin_calificar))
    assert_select "select[name=technician_id]", count: 0
  end
end

class Empresa::RankingTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:empresa)
    crear_escalones(companies(:tecnifrio))
    resolver_casos(users(:tecnico), mes_anterior, 11)
    resolver_casos(users(:tecnico_carlos), mes_anterior, 5)
  end

  test "muestra el ranking del mes elegido con escalón y bono" do
    get empresa_ranking_path(mes: mes_anterior.strftime("%Y-%m"))
    assert_response :success
    filas = css_select("tbody tr")
    assert_equal 2, filas.size
    assert_match "Juan Pérez", filas.first.text
    assert_match "Plata", filas.first.text
    assert_match "Carlos Mena", filas.last.text
    assert_match "Bronce", filas.last.text
  end

  test "en un mes cerrado ofrece registrar el pago; en el actual no" do
    get empresa_ranking_path(mes: mes_anterior.strftime("%Y-%m"))
    assert_select "input[type=submit][value='Registrar pago']", 2

    resolver_casos(users(:tecnico), mes_actual, 6)
    get empresa_ranking_path
    assert_select "input[type=submit][value='Registrar pago']", 0
    assert_match "Disponible al cerrar el mes", response.body
  end

  test "un mes futuro o inválido se corrige al mes actual" do
    get empresa_ranking_path(mes: "2099-12")
    assert_response :success
    get empresa_ranking_path(mes: "x")
    assert_response :success
  end
end

class Empresa::BonusTiersTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:empresa)
    @empresa = companies(:tecnifrio)
  end

  test "crea un escalón" do
    assert_difference "@empresa.bonus_tiers.count", 1 do
      post empresa_bonus_tiers_path, params: { bonus_tier: { nombre: "Bronce", casos_minimos: 5, porcentaje: 5 } }
    end
    assert_redirected_to empresa_bonus_tiers_path
  end

  test "rechaza escalones inválidos o incoherentes" do
    crear_escalones(@empresa)
    assert_no_difference "BonusTier.count" do
      post empresa_bonus_tiers_path, params: { bonus_tier: { nombre: "Raro", casos_minimos: 12, porcentaje: 3 } }
      assert_response :unprocessable_entity
      post empresa_bonus_tiers_path, params: { bonus_tier: { nombre: "", casos_minimos: 0, porcentaje: -1 } }
      assert_response :unprocessable_entity
    end
  end

  test "edita y elimina un escalón" do
    bronce = crear_escalones(@empresa).first
    patch empresa_bonus_tier_path(bronce), params: { bonus_tier: { porcentaje: 6 } }
    assert_redirected_to empresa_bonus_tiers_path
    assert_equal 6, bronce.reload.porcentaje

    assert_difference "BonusTier.count", -1 do
      delete empresa_bonus_tier_path(bronce)
    end
  end

  test "no puede tocar los escalones de otra empresa ni asignarse otra empresa por parámetro" do
    ajeno = BonusTier.create!(company: companies(:hogarfix), nombre: "Ajeno", casos_minimos: 3, porcentaje: 10)
    get edit_empresa_bonus_tier_path(ajeno)
    assert_response :not_found
    delete empresa_bonus_tier_path(ajeno)
    assert_response :not_found
    assert BonusTier.exists?(ajeno.id)

    post empresa_bonus_tiers_path, params: { bonus_tier: { nombre: "Mio", casos_minimos: 7, porcentaje: 20, company_id: companies(:hogarfix).id } }
    assert_equal @empresa, BonusTier.find_by!(nombre: "Mio").company
  end

  test "el listado muestra los escalones y los pagos recientes" do
    crear_escalones(@empresa)
    get empresa_bonus_tiers_path
    assert_response :success
    assert_select "td", text: /desde 10 casos/
  end
end

class Empresa::BonusPaymentsTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:empresa)
    @empresa = companies(:tecnifrio)
    crear_escalones(@empresa)
    resolver_casos(users(:tecnico), mes_anterior, 11)
  end

  test "registra el pago del escalón más alto de un mes cerrado" do
    assert_difference "BonusPayment.count", 1 do
      post empresa_bonus_payments_path, params: { technician_id: users(:tecnico).id, mes: mes_anterior.strftime("%Y-%m") }
    end
    pago = BonusPayment.last
    assert_equal "Plata", pago.tier_nombre
    assert_equal 50, pago.monto # 10 % de $500
    assert_equal users(:empresa), pago.registrado_por
    assert_redirected_to empresa_ranking_path(mes: mes_anterior.strftime("%Y-%m"))
  end

  test "no registra un pago duplicado" do
    2.times { post empresa_bonus_payments_path, params: { technician_id: users(:tecnico).id, mes: mes_anterior.strftime("%Y-%m") } }
    assert_equal 1, BonusPayment.count
    assert flash[:alert].present?
  end

  test "no registra pagos del mes en curso" do
    resolver_casos(users(:tecnico), mes_actual, 6)
    assert_no_difference "BonusPayment.count" do
      post empresa_bonus_payments_path, params: { technician_id: users(:tecnico).id, mes: mes_actual.strftime("%Y-%m") }
      post empresa_bonus_payments_path, params: { technician_id: users(:tecnico).id }
    end
  end

  test "no paga a quien no es técnico de la empresa" do
    assert_no_difference "BonusPayment.count" do
      post empresa_bonus_payments_path, params: { technician_id: users(:cliente).id, mes: mes_anterior.strftime("%Y-%m") }
    end
    assert_response :not_found
  end

  test "el historial lista los pagos registrados" do
    post empresa_bonus_payments_path, params: { technician_id: users(:tecnico).id, mes: mes_anterior.strftime("%Y-%m") }
    get empresa_bonus_payments_path
    assert_response :success
    assert_select "td", text: "Juan Pérez"
  end
end

class Empresa::RequisitosTest < ActionDispatch::IntegrationTest
  setup { login_as users(:empresa) }

  test "la empresa ajusta la nota mínima y los casos mínimos" do
    patch empresa_requisitos_path, params: { company: { min_calificacion: 4.5, min_casos_participar: 25 } }
    assert_redirected_to empresa_bonus_tiers_path
    empresa = companies(:tecnifrio).reload
    assert_equal 4.5, empresa.min_calificacion.to_f
    assert_equal 25, empresa.min_casos_participar
  end

  test "rechaza valores fuera de rango" do
    patch empresa_requisitos_path, params: { company: { min_calificacion: 9, min_casos_participar: 0 } }
    assert_equal 4.2, companies(:tecnifrio).reload.min_calificacion.to_f
    assert flash[:alert].present?
  end

  test "solo cambia los requisitos de su propia empresa" do
    patch empresa_requisitos_path, params: { company: { min_calificacion: 3, id: companies(:hogarfix).id, company_id: companies(:hogarfix).id, status: "suspendida" } }
    assert_equal 4.2, companies(:hogarfix).reload.min_calificacion.to_f
    assert_equal "activa", companies(:tecnifrio).reload.status, "no puede cambiar su propio estado"
  end

  test "la página de bonos muestra los requisitos actuales" do
    get empresa_bonus_tiers_path
    assert_select "input[name='company[min_calificacion]']"
    assert_select "input[name='company[min_casos_participar]']"
  end

  test "un técnico o un cliente no pueden cambiar los requisitos" do
    delete logout_path
    login_as users(:tecnico)
    patch empresa_requisitos_path, params: { company: { min_calificacion: 1 } }
    assert_redirected_to root_url
    assert_equal 4.2, companies(:tecnifrio).reload.min_calificacion.to_f
  end
end

class Empresa::TechniciansTest < ActionDispatch::IntegrationTest
  setup { login_as users(:empresa) }

  test "lista a los técnicos de la empresa con su sueldo base" do
    get empresa_technicians_path
    assert_response :success
    assert_select "td", text: "Juan Pérez"
    assert_select "td", text: "Carlos Mena"
    assert_select "td", text: "Marta Ruiz", count: 0 # no es técnico
  end

  test "registra el sueldo base de un técnico" do
    patch empresa_technician_path(users(:tecnico)), params: { user: { sueldo_base: "650.50" } }
    assert_redirected_to empresa_technicians_path
    assert_equal 650.5, users(:tecnico).reload.sueldo_base.to_f
  end

  test "rechaza un sueldo inválido" do
    patch empresa_technician_path(users(:tecnico)), params: { user: { sueldo_base: "-5" } }
    assert_response :unprocessable_entity
    assert_equal 500, users(:tecnico).reload.sueldo_base
  end

  test "la empresa solo puede cambiar el sueldo, nunca el rol, la cédula ni la contraseña" do
    patch empresa_technician_path(users(:tecnico)), params: { user: { sueldo_base: 700, role: "admin", cedula: "1700000019", password: "hackeado1", activo: false } }
    tecnico = users(:tecnico).reload
    assert_equal 700, tecnico.sueldo_base
    assert_equal "tecnico", tecnico.role
    assert_equal "0100000025", tecnico.cedula
    assert tecnico.activo?
    assert tecnico.authenticate(LoginHelper::PASSWORD_DE_PRUEBA)
  end

  test "no puede ver ni editar técnicos de otra empresa ni a usuarios que no son técnicos" do
    otro = User.create!(username: "tecnico.ajeno", nombre_completo: "Ajeno Otra", cedula: "0400000014", role: "tecnico",
                        company: companies(:hogarfix), password: "password123")
    get edit_empresa_technician_path(otro)
    assert_response :not_found
    patch empresa_technician_path(otro), params: { user: { sueldo_base: 999 } }
    assert_response :not_found
    assert_nil otro.reload.sueldo_base

    patch empresa_technician_path(users(:cliente)), params: { user: { sueldo_base: 999 } }
    assert_response :not_found
  end
end

class Empresa::RankingRequisitosTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:empresa)
    crear_escalones(companies(:tecnifrio))
  end

  test "el ranking separa a quienes participan de quienes no, con el motivo" do
    resolver_casos(users(:tecnico), mes_anterior, 12, calificacion: 5)
    resolver_casos(users(:tecnico_carlos), mes_anterior, 12, calificacion: 3)

    get empresa_ranking_path(mes: mes_anterior.strftime("%Y-%m"))
    assert_response :success
    assert_select "h2", text: "Participan en el ranking"
    assert_select "h2", text: "No participan este mes"
    assert_match "Calificación 3,00 menor a 4,20", response.body
    assert_equal 1, css_select(".pos").size
    assert_select "input[type=submit][value='Registrar pago']", 1
  end

  test "sin sueldo base ofrece definirlo en lugar de registrar el pago" do
    users(:tecnico).update!(sueldo_base: nil)
    resolver_casos(users(:tecnico), mes_anterior, 6)

    get empresa_ranking_path(mes: mes_anterior.strftime("%Y-%m"))
    assert_select "a", text: "Definir sueldo base"
    assert_select "input[type=submit][value='Registrar pago']", 0
  end

  test "no registra el pago de un técnico que no cumple los requisitos" do
    resolver_casos(users(:tecnico), mes_anterior, 12, calificacion: 3)
    assert_no_difference "BonusPayment.count" do
      post empresa_bonus_payments_path, params: { technician_id: users(:tecnico).id, mes: mes_anterior.strftime("%Y-%m") }
    end
    assert_match(/no cumple los requisitos/, flash[:alert])
  end

  test "el pago muestra el cálculo: porcentaje, sueldo base y monto" do
    resolver_casos(users(:tecnico), mes_anterior, 11)
    post empresa_bonus_payments_path, params: { technician_id: users(:tecnico).id, mes: mes_anterior.strftime("%Y-%m") }
    get empresa_bonus_payments_path
    assert_match "10 % de $500,00", response.body
    assert_match "$50,00", response.body
  end
end
