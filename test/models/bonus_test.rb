require "test_helper"

class BonusTierTest < ActiveSupport::TestCase
  setup do
    @empresa = companies(:tecnifrio)
    @bronce, @plata, @oro = crear_escalones(@empresa) # 5 casos 5 %, 10 casos 10 %, 15 casos 15 %
  end

  def nuevo(**atributos) = BonusTier.new({ company: @empresa, nombre: "Extra", casos_minimos: 20, porcentaje: 20 }.merge(atributos))

  test "un escalón válido se guarda" do
    assert nuevo.valid?
  end

  test "exige nombre, casos mínimos positivos y porcentaje entre 0 y 100" do
    assert_not nuevo(nombre: "").valid?
    assert_not nuevo(casos_minimos: 0).valid?
    assert_not nuevo(casos_minimos: 2.5).valid?
    assert_not nuevo(porcentaje: 0).valid?
    assert_not nuevo(porcentaje: -5).valid?
    assert_not nuevo(porcentaje: 101).valid?
  end

  test "no repite los casos mínimos ni el nombre dentro de la empresa" do
    assert_not nuevo(casos_minimos: 5, porcentaje: 6).valid?
    assert_not nuevo(nombre: "plata").valid?
  end

  test "otra empresa puede usar los mismos valores" do
    assert BonusTier.new(company: companies(:hogarfix), nombre: "Bronce", casos_minimos: 5, porcentaje: 5).valid?
  end

  test "un escalón con más casos debe pagar un porcentaje mayor" do
    caso = nuevo(casos_minimos: 12, porcentaje: 8) # entre Plata (10, 10 %) y Oro (15, 15 %): paga menos que Plata
    assert_not caso.valid?
    assert caso.errors[:porcentaje].any?

    assert nuevo(casos_minimos: 12, porcentaje: 12).valid?
  end

  test "al editar un escalón no se compara contra sí mismo" do
    @plata.porcentaje = 12
    assert @plata.valid?
    @plata.porcentaje = 20 # supera al de Oro (15 %)
    assert_not @plata.valid?
  end

  test "monto_para aplica el porcentaje al sueldo base" do
    assert_equal 50, @plata.monto_para(500)
    assert_equal 26, BonusTier.new(porcentaje: 5).monto_para(520)
    assert_equal 37.5, @oro.monto_para(250)
    assert_equal 0, @plata.monto_para(nil)
  end
end

class BonusPaymentTest < ActiveSupport::TestCase
  setup do
    @empresa = companies(:tecnifrio)
    @juan = users(:tecnico)             # sueldo base $500
    @carlos = users(:tecnico_carlos)    # sueldo base $600
    @registra = users(:empresa)
    crear_escalones(@empresa)
  end

  def registrar(tecnico = @juan, periodo = mes_anterior, **extra)
    BonusPayment.registrar(company: @empresa, technician: tecnico, periodo: periodo, por: @registra, **extra)
  end

  test "registra el escalón más alto alcanzado calculado como porcentaje del sueldo base" do
    resolver_casos(@juan, mes_anterior, 11)
    pago = registrar(nota: "Pagado en efectivo")

    assert pago.persisted?, pago.errors.full_messages.to_sentence
    assert_equal "Plata", pago.tier_nombre
    assert_equal 11, pago.casos_resueltos
    assert_equal 10, pago.casos_minimos
    assert_equal 10, pago.porcentaje
    assert_equal 500, pago.sueldo_base
    assert_equal 50, pago.monto # 10 % de $500
    assert_equal 5.0, pago.promedio.to_f
    assert_equal mes_anterior, pago.periodo
    assert_equal @registra, pago.registrado_por
    assert_equal "Pagado en efectivo", pago.nota
  end

  test "cada técnico cobra según su propio sueldo base" do
    resolver_casos(@carlos, mes_anterior, 5)
    assert_equal 30, registrar(@carlos).monto # 5 % de $600
  end

  test "no se paga un mes que todavía no termina" do
    resolver_casos(@juan, mes_actual, 6)
    pago = registrar(@juan, mes_actual)
    assert_not pago.persisted?
    assert pago.errors[:periodo].any?
  end

  test "no se paga si no alcanzó ningún escalón" do
    resolver_casos(@juan, mes_anterior, 2)
    pago = registrar
    assert_not pago.persisted?
    assert_match(/no alcanzó ningún escalón/, pago.errors.full_messages.to_sentence)
  end

  test "no se paga a un técnico que no cumple los requisitos de nota" do
    resolver_casos(@juan, mes_anterior, 12, calificacion: 4) # promedio 4,0 < 4,2
    pago = registrar
    assert_not pago.persisted?
    assert_match(/no cumple los requisitos/, pago.errors.full_messages.to_sentence)
    assert_equal 0, BonusPayment.count
  end

  test "no se paga a un técnico que no llega al mínimo de casos" do
    @empresa.update!(min_casos_participar: 8)
    resolver_casos(@juan, mes_anterior, 6)
    assert_not registrar.persisted?
  end

  test "no se paga sin sueldo base registrado" do
    @juan.update!(sueldo_base: nil)
    resolver_casos(@juan, mes_anterior, 11)
    pago = registrar
    assert_not pago.persisted?
    assert_match(/sueldo base/, pago.errors.full_messages.to_sentence)
  end

  test "un técnico solo tiene un pago por mes" do
    resolver_casos(@juan, mes_anterior, 6)
    assert registrar.persisted?
    segundo = registrar
    assert_not segundo.persisted?
    assert_equal 1, BonusPayment.where(technician: @juan).count
  end

  test "solo se paga a técnicos de la empresa" do
    otra = companies(:hogarfix)
    pago = BonusPayment.registrar(company: otra, technician: @juan, periodo: mes_anterior, por: users(:empresa_hogarfix))
    assert_not pago.persisted?
  end

  test "el historial conserva el cálculo aunque la empresa cambie escalones o sueldo" do
    resolver_casos(@juan, mes_anterior, 10)
    pago = registrar
    escalon = pago.bonus_tier

    escalon.update!(porcentaje: 12)
    @juan.update!(sueldo_base: 900)
    pago.reload
    assert_equal 50, pago.monto
    assert_equal 500, pago.sueldo_base
    assert_equal 10, pago.porcentaje

    escalon.destroy
    pago.reload
    assert_nil pago.bonus_tier
    assert_equal "Plata", pago.tier_nombre
    assert_equal 50, pago.monto
  end

  test "no se puede borrar a un técnico con pagos registrados" do
    resolver_casos(@juan, mes_anterior, 5)
    registrar
    assert_not @juan.destroy
  end
end

class RequisitosTest < ActiveSupport::TestCase
  test "la empresa nueva parte con nota mínima 4,2 y 20 casos" do
    empresa = Company.new
    assert_equal 4.2, empresa.min_calificacion.to_f
    assert_equal 20, empresa.min_casos_participar
  end

  test "valida los límites de los requisitos" do
    empresa = companies(:tecnifrio)
    assert empresa.update(min_calificacion: 4.5, min_casos_participar: 25)
    assert_not empresa.update(min_calificacion: 0.5)
    assert_not empresa.update(min_calificacion: 5.5)
    assert_not empresa.update(min_casos_participar: 0)
    assert_not empresa.update(min_casos_participar: 2.5)
    assert_not empresa.update(min_casos_participar: 1000)
  end

  test "el sueldo base solo aplica a técnicos y debe ser positivo" do
    assert users(:tecnico).update(sueldo_base: 750)
    assert_not users(:tecnico).update(sueldo_base: 0)
    assert_not users(:tecnico).update(sueldo_base: -10)
    assert_not users(:cliente).update(sueldo_base: 500)
    assert users(:cliente).update(sueldo_base: nil)
  end
end
