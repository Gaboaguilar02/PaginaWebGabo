require "test_helper"

class BonusTierTest < ActiveSupport::TestCase
  setup do
    @empresa = companies(:tecnifrio)
    @bronce, @plata, @oro = crear_escalones(@empresa)
  end

  def nuevo(**atributos) = BonusTier.new({ company: @empresa, nombre: "Extra", casos_minimos: 20, monto: 150 }.merge(atributos))

  test "un escalón válido se guarda" do
    assert nuevo.valid?
  end

  test "exige nombre, casos mínimos positivos y monto positivo" do
    assert_not nuevo(nombre: "").valid?
    assert_not nuevo(casos_minimos: 0).valid?
    assert_not nuevo(casos_minimos: 2.5).valid?
    assert_not nuevo(monto: 0).valid?
    assert_not nuevo(monto: -5).valid?
  end

  test "no repite los casos mínimos ni el nombre dentro de la empresa" do
    assert_not nuevo(casos_minimos: 5, monto: 31).valid?
    assert_not nuevo(nombre: "plata").valid?
  end

  test "otra empresa puede usar los mismos valores" do
    assert BonusTier.new(company: companies(:hogarfix), nombre: "Bronce", casos_minimos: 5, monto: 10).valid?
  end

  test "un escalón con más casos debe pagar más" do
    caso = nuevo(casos_minimos: 12, monto: 50) # entre Plata (10, $60) y Oro (15, $100): paga menos que Plata
    assert_not caso.valid?
    assert caso.errors[:monto].any?

    assert nuevo(casos_minimos: 12, monto: 80).valid?
  end

  test "al editar un escalón no se compara contra sí mismo" do
    @plata.monto = 70
    assert @plata.valid?
    @plata.monto = 110
    assert_not @plata.valid?
  end

  test "alcanzado devuelve el escalón más alto cumplido" do
    assert_nil BonusTier.alcanzado(@empresa, 4)
    assert_equal @bronce, BonusTier.alcanzado(@empresa, 5)
    assert_equal @bronce, BonusTier.alcanzado(@empresa, 9)
    assert_equal @plata, BonusTier.alcanzado(@empresa, 10)
    assert_equal @oro, BonusTier.alcanzado(@empresa, 99)
  end
end

class BonusPaymentTest < ActiveSupport::TestCase
  setup do
    @empresa = companies(:tecnifrio)
    @juan = users(:tecnico)
    @registra = users(:empresa)
    crear_escalones(@empresa)
  end

  def registrar(tecnico = @juan, periodo = mes_anterior, **extra)
    BonusPayment.registrar(company: @empresa, technician: tecnico, periodo: periodo, por: @registra, **extra)
  end

  test "registra el escalón más alto alcanzado, con sus casos y monto" do
    resolver_casos(@juan, mes_anterior, 11)
    pago = registrar(nota: "Pagado en efectivo")

    assert pago.persisted?, pago.errors.full_messages.to_sentence
    assert_equal "Plata", pago.tier_nombre
    assert_equal 11, pago.casos_resueltos
    assert_equal 10, pago.casos_minimos
    assert_equal 60, pago.monto
    assert_equal mes_anterior, pago.periodo
    assert_equal @registra, pago.registrado_por
    assert_equal "Pagado en efectivo", pago.nota
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

  test "el historial conserva el escalón aunque la empresa lo cambie o lo elimine" do
    resolver_casos(@juan, mes_anterior, 10)
    pago = registrar
    escalon = pago.bonus_tier

    escalon.update!(monto: 75)
    assert_equal 60, pago.reload.monto

    escalon.destroy
    pago.reload
    assert_nil pago.bonus_tier
    assert_equal "Plata", pago.tier_nombre
    assert_equal 60, pago.monto
  end

  test "no se puede borrar a un técnico con pagos registrados" do
    resolver_casos(@juan, mes_anterior, 5)
    registrar
    assert_not @juan.destroy
  end
end
