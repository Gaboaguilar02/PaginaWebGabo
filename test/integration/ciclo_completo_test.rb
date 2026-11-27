require "test_helper"

# El flujo funcional completo de UFix, de punta a punta y con los cuatro roles:
# cliente pide -> empresa acepta y asigna -> técnico resuelve -> cliente califica -> ranking y bono.
class CicloCompletoTest < ActionDispatch::IntegrationTest
  test "una solicitud recorre todo el ciclo y alimenta el ranking y la reputación" do
    empresa = companies(:tecnifrio)
    # Con 1 caso resuelto en el mes ya se alcanza el primer escalón.
    BonusTier.create!(company: empresa, nombre: "Inicial", casos_minimos: 1, porcentaje: 10)

    # 1. El cliente pide el servicio
    login_as users(:cliente)
    assert_difference "RepairCase.count", 1 do
      post cliente_repair_cases_path, params: { repair_case: {
        appliance_type_id: appliance_types(:lavadora).id, city_id: cities(:quito).id, company_id: empresa.id,
        falla: "La lavadora no desagua y deja el agua estancada.", direccion: "Av. Amazonas N24-15"
      } }
    end
    caso = RepairCase.order(:id).last
    assert_equal "solicitada", caso.status
    delete logout_path

    # 2. La empresa lo acepta y asigna a Juan
    login_as users(:empresa)
    patch aceptar_empresa_repair_case_path(caso)
    patch asignar_empresa_repair_case_path(caso), params: { technician_id: users(:tecnico).id }
    assert_equal "asignada", caso.reload.status
    delete logout_path

    # 3. El técnico atiende y resuelve
    login_as users(:tecnico)
    patch salir_tecnico_repair_case_path(caso)
    patch iniciar_tecnico_repair_case_path(caso)
    patch resolver_tecnico_repair_case_path(caso), params: { informe_tecnico: "Se destapó la manguera de desagüe y se probó el ciclo." }
    caso.reload
    assert_equal "resuelta", caso.status
    delete logout_path

    # 4. El cliente califica
    login_as users(:cliente)
    patch calificar_cliente_repair_case_path(caso), params: { calificacion: 5, comentario_feedback: "Excelente servicio" }
    assert_equal 5, caso.reload.calificacion
    delete logout_path

    # 5. El ranking de la empresa lo refleja y el técnico ve su escalón
    fila = MonthlyRanking.new(empresa, Date.current).fila_de(users(:tecnico))
    assert_equal 1, fila.resueltos
    assert_equal 1, fila.posicion
    assert_equal 5.0, fila.promedio
    assert_equal "Inicial", fila.tier.nombre
    assert_equal 1, empresa.reload.reviews_count
    assert_equal 5.0, empresa.rating_promedio.to_f

    login_as users(:tecnico)
    get tecnico_desempeno_path
    assert_select "tr.row--me", text: /Inicial/
  end
end
