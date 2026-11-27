require "test_helper"

class MonthlyRankingTest < ActiveSupport::TestCase
  setup do
    @empresa = companies(:tecnifrio) # en los fixtures: mínimo 1 caso y nota mínima 4,2 (por defecto)
    @juan = users(:tecnico)           # sueldo base $500
    @carlos = users(:tecnico_carlos)  # sueldo base $600
    crear_escalones(@empresa)         # Bronce 5 casos 5 %, Plata 10 casos 10 %, Oro 15 casos 15 %
  end

  def ranking(mes = mes_actual) = MonthlyRanking.new(@empresa, mes)

  # ---------- Orden y posiciones
  test "ordena por casos resueltos del mes y asigna posiciones" do
    resolver_casos(@juan, mes_anterior, 3)
    resolver_casos(@carlos, mes_anterior, 6)

    filas = ranking(mes_anterior).filas
    assert_equal [ @carlos, @juan ], filas.map(&:technician)
    assert_equal [ 1, 2 ], filas.map(&:posicion)
    assert_equal [ 6, 3 ], filas.map(&:resueltos)
  end

  test "si empatan en casos gana la mejor calificación promedio" do
    @empresa.update!(min_calificacion: 1) # para comparar notas bajas sin que los excluya el requisito
    resolver_casos(@juan, mes_anterior, 4, calificacion: 3)
    resolver_casos(@carlos, mes_anterior, 4, calificacion: 5)

    filas = ranking(mes_anterior).filas
    assert_equal @carlos, filas.first.technician
    assert_equal [ 1, 2 ], filas.map(&:posicion)
  end

  test "empate total comparte posición" do
    resolver_casos(@juan, mes_anterior, 2, calificacion: 5)
    resolver_casos(@carlos, mes_anterior, 2, calificacion: 5)

    assert_equal [ 1, 1 ], ranking(mes_anterior).filas.map(&:posicion)
  end

  test "solo cuentan los casos resueltos dentro del mes (por fecha de resolución)" do
    resolver_casos(@juan, mes_anterior, 4)
    resolver_casos(@juan, mes_actual, 2)

    assert_equal 4, ranking(mes_anterior).fila_de(@juan).resueltos
    assert_equal 2, ranking(mes_actual).fila_de(@juan).resueltos
  end

  test "los casos que no están resueltos no suman" do
    assert_equal 0, ranking.fila_de(@juan).resueltos # fixtures en reparación y solicitada
  end

  # ---------- Requisitos para participar
  test "participa quien cumple la nota mínima y los casos mínimos" do
    resolver_casos(@juan, mes_anterior, 6, calificacion: 5)
    fila = ranking(mes_anterior).fila_de(@juan)
    assert fila.participa?
    assert_empty fila.motivos
    assert_equal 1, fila.posicion
  end

  test "no participa si su calificación promedio es menor a la mínima" do
    resolver_casos(@juan, mes_anterior, 12, calificacion: 4) # promedio 4,0 < 4,2
    fila = ranking(mes_anterior).fila_de(@juan)
    assert_not fila.participa?
    assert_nil fila.posicion
    assert_nil fila.tier, "sin requisitos no hay escalón aunque tenga casos de sobra"
    assert_equal 0, fila.bono
    assert_match(/calificación 4,00 menor a 4,20/, fila.motivos.to_sentence)
  end

  test "la nota mínima exacta sí cumple (>= y no >)" do
    @empresa.update!(min_calificacion: 4)
    resolver_casos(@juan, mes_anterior, 5, calificacion: 4)
    assert ranking(mes_anterior).fila_de(@juan).participa?
  end

  test "no participa si no llega al mínimo de casos aunque su nota sea perfecta" do
    @empresa.update!(min_casos_participar: 20)
    resolver_casos(@juan, mes_anterior, 18, calificacion: 5)
    fila = ranking(mes_anterior).fila_de(@juan)
    assert_not fila.participa?
    assert_equal [ "18 de 20 casos requeridos" ], fila.motivos
    assert_nil fila.tier
  end

  test "con exactamente el mínimo de casos sí participa" do
    @empresa.update!(min_casos_participar: 20)
    resolver_casos(@juan, mes_anterior, 20)
    assert ranking(mes_anterior).fila_de(@juan).participa?
  end

  test "sin calificaciones de clientes no se puede verificar la nota y no participa" do
    resolver_casos(@juan, mes_anterior, 8, calificacion: nil)
    fila = ranking(mes_anterior).fila_de(@juan)
    assert_not fila.participa?
    assert_includes fila.motivos, "sin calificaciones de clientes"
  end

  test "la nota se calcula solo con los casos calificados" do
    resolver_casos(@juan, mes_anterior, 3, calificacion: 5)
    resolver_casos(@juan, mes_anterior, 5, calificacion: nil) # sin calificar: no bajan el promedio
    fila = ranking(mes_anterior).fila_de(@juan)
    assert_equal 8, fila.resueltos
    assert_equal 3, fila.calificados
    assert_equal 5.0, fila.promedio
    assert fila.participa?
  end

  test "puede incumplir los dos requisitos a la vez y se listan ambos motivos" do
    @empresa.update!(min_casos_participar: 20)
    resolver_casos(@juan, mes_anterior, 5, calificacion: 3)
    assert_equal 2, ranking(mes_anterior).fila_de(@juan).motivos.size
  end

  test "los que no participan van al final, sin posición, y no cuentan para el ranking" do
    resolver_casos(@juan, mes_anterior, 30, calificacion: 3)   # muchos casos pero mala nota
    resolver_casos(@carlos, mes_anterior, 5, calificacion: 5)  # pocos casos pero cumple

    r = ranking(mes_anterior)
    assert_equal [ @carlos ], r.participantes.map(&:technician)
    assert_equal [ @juan ], r.no_participantes.map(&:technician)
    assert_equal [ @carlos, @juan ], r.filas.map(&:technician)
    assert_equal 1, r.fila_de(@carlos).posicion
    assert_nil r.fila_de(@juan).posicion
  end

  test "cada empresa usa sus propios requisitos" do
    resolver_casos(@juan, mes_anterior, 5, calificacion: 4)
    @empresa.update!(min_calificacion: 4.5)
    assert_not ranking(mes_anterior).fila_de(@juan).participa?
    @empresa.update!(min_calificacion: 3.5)
    assert ranking(mes_anterior).fila_de(@juan).participa?
  end

  # ---------- Escalón y dinero
  test "el técnico recibe solo el escalón más alto alcanzado, como porcentaje de su sueldo base" do
    resolver_casos(@juan, mes_anterior, 12)
    resolver_casos(@carlos, mes_anterior, 5)

    fila_juan = ranking(mes_anterior).fila_de(@juan)
    assert_equal "Plata", fila_juan.tier.nombre
    assert_equal 50, fila_juan.bono # 10 % de $500, no 5 % + 10 %

    fila_carlos = ranking(mes_anterior).fila_de(@carlos)
    assert_equal "Bronce", fila_carlos.tier.nombre
    assert_equal 30, fila_carlos.bono # 5 % de $600
  end

  test "con menos casos que el primer escalón no hay bono aunque participe" do
    resolver_casos(@juan, mes_anterior, 4)
    fila = ranking(mes_anterior).fila_de(@juan)
    assert fila.participa?
    assert_nil fila.tier
    assert_equal 0, fila.bono
  end

  test "sin sueldo base registrado no se calcula el dinero y se avisa" do
    @juan.update!(sueldo_base: nil)
    resolver_casos(@juan, mes_anterior, 6)
    fila = ranking(mes_anterior).fila_de(@juan)
    assert_equal "Bronce", fila.tier.nombre
    assert fila.falta_sueldo?
    assert_equal 0, fila.bono
    assert_not fila.con_bono?
  end

  test "lista también a los técnicos sin casos y no incluye a otros roles ni a otras empresas" do
    tecnicos = ranking.filas.map(&:technician)
    assert_includes tecnicos, @juan
    assert_includes tecnicos, @carlos
    assert_not_includes tecnicos, users(:empresa)
    assert_not_includes tecnicos, users(:cliente)
  end

  test "no mezcla casos de otra empresa" do
    assert_empty MonthlyRanking.new(companies(:hogarfix), mes_actual).filas
  end

  test "totales: resueltos, bonos y pendientes de pago" do
    resolver_casos(@juan, mes_anterior, 10)
    resolver_casos(@carlos, mes_anterior, 5)
    r = ranking(mes_anterior)

    assert_equal 15, r.total_resueltos
    assert_equal 80, r.total_bonos # Plata 10 % de $500 = 50 + Bronce 5 % de $600 = 30
    assert_equal 2, r.pendientes_de_pago.size
    assert_equal 0, r.total_pagado
  end

  test "el bono de quien no participa no suma a los totales" do
    resolver_casos(@juan, mes_anterior, 12, calificacion: 3)
    assert_equal 0, ranking(mes_anterior).total_bonos
  end

  test "el mes actual no está cerrado y el anterior sí" do
    assert_not ranking(mes_actual).cerrado?
    assert ranking(mes_anterior).cerrado?
  end

  test "promedio general del período" do
    resolver_casos(@juan, mes_anterior, 2, calificacion: 5)
    resolver_casos(@carlos, mes_anterior, 2, calificacion: 3)
    assert_equal 4.0, ranking(mes_anterior).promedio_general.to_f
  end
end
