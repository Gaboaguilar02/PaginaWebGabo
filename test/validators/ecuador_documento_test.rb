require "minitest/autorun"
require_relative "../../app/validators/ecuador_documento"

# Prueba de Ruby puro: no necesita Rails ni base de datos.
#   ruby test/validators/ecuador_documento_test.rb
class EcuadorDocumentoTest < Minitest::Test
  CEDULAS_VALIDAS = %w[ 1710034065 1700000019 0900000076 0100000025 1712345675 ].freeze
  RUC_SOCIEDAD = %w[ 1790001237001 0990000018001 1791234561001 ].freeze
  RUC_PUBLICO = %w[ 1760000150001 0960000140001 ].freeze

  def test_acepta_cedulas_validas
    CEDULAS_VALIDAS.each { |c| assert EcuadorDocumento.cedula_valida?(c), "#{c} debería ser válida" }
  end

  def test_rechaza_cedula_con_digito_verificador_incorrecto
    refute EcuadorDocumento.cedula_valida?("1710034066")
    refute EcuadorDocumento.cedula_valida?("1700000010")
  end

  def test_rechaza_cedula_con_formato_incorrecto
    [ "", nil, "123", "17100340651", "17100340AB", "1710 03406", "abcdefghij" ].each do |c|
      refute EcuadorDocumento.cedula_valida?(c), "#{c.inspect} no debería ser válida"
    end
  end

  def test_rechaza_cedula_con_provincia_inexistente
    refute EcuadorDocumento.cedula_valida?("2510034069")
    refute EcuadorDocumento.cedula_valida?("0010034069")
  end

  def test_rechaza_cedula_con_tercer_digito_mayor_a_cinco
    refute EcuadorDocumento.cedula_valida?("1760034068")
  end

  def test_acepta_ruc_de_persona_natural
    assert EcuadorDocumento.ruc_valido?("1710034065001")
  end

  def test_acepta_ruc_de_sociedad_privada
    RUC_SOCIEDAD.each { |r| assert EcuadorDocumento.ruc_valido?(r), "#{r} debería ser válido" }
  end

  def test_acepta_ruc_de_entidad_publica
    RUC_PUBLICO.each { |r| assert EcuadorDocumento.ruc_valido?(r), "#{r} debería ser válido" }
  end

  def test_rechaza_ruc_con_establecimiento_en_cero
    refute EcuadorDocumento.ruc_valido?("1710034065000")
    refute EcuadorDocumento.ruc_valido?("1790001237000")
  end

  def test_rechaza_ruc_con_digito_verificador_incorrecto
    refute EcuadorDocumento.ruc_valido?("1790001238001")
    refute EcuadorDocumento.ruc_valido?("1760000160001")
  end

  def test_rechaza_ruc_con_formato_incorrecto
    [ "", nil, "1790001237", "17900012370011", "17900012AB001" ].each do |r|
      refute EcuadorDocumento.ruc_valido?(r), "#{r.inspect} no debería ser válido"
    end
  end
end
