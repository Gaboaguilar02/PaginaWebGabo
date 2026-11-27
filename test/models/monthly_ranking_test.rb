require "test_helper"

class MonthlyRankingTest < ActiveSupport::TestCase
  setup do
    @empresa = companies(:tecnifrio)
    @juan = users(:tecnico)
    @carlos = users(:tecnico_carlos)
    crear_escalones(@empresa)
  end

  def ranking(mes = mes_actual) = MonthlyRanking.new(@empresa, mes)

  test "ordena por casos resueltos del mes y asigna posiciones" do
    resolver_casos(@juan, mes_anterior, 3)
    resolver_casos(@carlos, mes_anterior, 6)

    filas = ranking(mes_anterior).filas
    assert_equal [ @carlos, @juan ], filas.map(&:technician)
    assert_equal [ 1, 2 ], filas.map(&:posicion)
    assert_equal [ 6, 3 ], filas.map(&:resueltos)
  end

  test "si empatan en casos gana la mejor calificación promedio" do
    resolver_casos(@juan, mes_anterior, 4, calificacion: 3)
    resolver_casos(@carlos, mes_anterior, 4, calificacion: 5)

    filas = ranking(mes_anterior).filas
    assert_equal @carlos, filas.first.technician
    assert_equal [ 1, 2 ], filas.map(&:posicion)
  end

  test "empate total comparte posición" do
    resolver_casos(@juan, mes_anterior, 2, calificacion: 4)
    resolver_casos(@carlos, mes_anterior, 2, calificacion: 4)

    assert_equal [ 1, 1 ], ranking(mes_anterior).filas.map(&:posicion)
  end

  test "solo cuentan los casos resueltos dentro del mes (por fecha de resolución)" do
    resolver_casos(@juan, mes_anterior, 4)
    resolver_casos(@juan, mes_actual, 2)

    assert_equal 4, ranking(mes_anterior).fila_de(@juan).resueltos
    assert_equal 2, ranking(mes_actual).fila_de(@juan).resueltos
  end

  test "los casos que no están resueltos no suman" do
    assert_equal 0, ranking.fila_de(@juan).resueltos # fixture en_reparación y solicitada
  end

  test "el técnico recibe solo el escalón más alto alcanzado" do
    resolver_casos(@juan, mes_anterior, 12)
    resolver_casos(@carlos, mes_anterior, 5)

    fila_juan = ranking(mes_anterior).fila_de(@juan)
    assert_equal "Plata", fila_juan.tier.nombre
    assert_equal 60, fila_juan.bono

    fila_carlos = ranking(mes_anterior).fila_de(@carlos)
    assert_equal "Bronce", fila_carlos.tier.nombre
    assert_equal 30, fila_carlos.bono
  end

  test "con menos casos que el primer escalón no hay bono" do
    resolver_casos(@juan, mes_anterior, 4)
    fila = ranking(mes_anterior).fila_de(@juan)
    assert_nil fila.tier
    assert_equal 0, fila.bono
  end

  test "lista también a los técnicos sin casos y no incluye a otros roles ni a otras empresas" do
    tecnicos = ranking.filas.map(&:technician)
    assert_includes tecnicos, @juan
    assert_includes tecnicos, @carlos
    assert_not_includes tecnicos, users(:empresa)
    assert_not_includes tecnicos, users(:cliente)
  end

  test "no mezcla casos de otra empresa" do
    otra = companies(:hogarfix)
    assert_empty MonthlyRanking.new(otra, mes_actual).filas
  end

  test "totales: resueltos, bonos y pendientes de pago" do
    resolver_casos(@juan, mes_anterior, 10)
    resolver_casos(@carlos, mes_anterior, 5)
    r = ranking(mes_anterior)

    assert_equal 15, r.total_resueltos
    assert_equal 90, r.total_bonos # Plata 60 + Bronce 30
    assert_equal 2, r.pendientes_de_pago.size
    assert_equal 0, r.total_pagado
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
