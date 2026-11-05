# Algoritmos oficiales para validar documentos de identificación de Ecuador.
# Es Ruby puro (sin dependencias de Rails) para poder probarlo de forma aislada.
#
# - Cédula: 10 dígitos, módulo 10.
# - RUC: 13 dígitos. Persona natural (cédula + establecimiento), sociedad
#   privada (tercer dígito 9) o entidad pública (tercer dígito 6), módulo 11.
module EcuadorDocumento
  CODIGOS_PROVINCIA = ((1..24).to_a + [ 30 ]).freeze
  COEFICIENTES_SOCIEDAD = [ 4, 3, 2, 7, 6, 5, 4, 3, 2 ].freeze
  COEFICIENTES_PUBLICO = [ 3, 2, 7, 6, 5, 4, 3, 2 ].freeze

  module_function

  def cedula_valida?(valor)
    cedula = valor.to_s
    return false unless cedula.match?(/\A\d{10}\z/)
    return false unless CODIGOS_PROVINCIA.include?(cedula[0, 2].to_i)
    return false if cedula[2].to_i > 5

    digitos = cedula.chars.map(&:to_i)
    suma = digitos.first(9).each_with_index.sum do |digito, indice|
      producto = digito * (indice.even? ? 2 : 1)
      producto > 9 ? producto - 9 : producto
    end

    (10 - suma % 10) % 10 == digitos[9]
  end

  def ruc_valido?(valor)
    ruc = valor.to_s
    return false unless ruc.match?(/\A\d{13}\z/)
    return false unless CODIGOS_PROVINCIA.include?(ruc[0, 2].to_i)

    digitos = ruc.chars.map(&:to_i)

    case digitos[2]
    when 0..5
      cedula_valida?(ruc[0, 10]) && ruc[10, 3].to_i >= 1
    when 6
      digito_modulo11(digitos.first(8), COEFICIENTES_PUBLICO) == digitos[8] && ruc[9, 4].to_i >= 1
    when 9
      digito_modulo11(digitos.first(9), COEFICIENTES_SOCIEDAD) == digitos[9] && ruc[10, 3].to_i >= 1
    else
      false
    end
  end

  def digito_modulo11(digitos, coeficientes)
    suma = digitos.zip(coeficientes).sum { |digito, coeficiente| digito * coeficiente }
    residuo = suma % 11
    residuo.zero? ? 0 : 11 - residuo
  end
end
