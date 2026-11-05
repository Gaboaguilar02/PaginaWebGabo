# Uso: validates :cedula, cedula: true
# Valida en el servidor (back-end) que la cédula ecuatoriana sea correcta.
class CedulaValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    unless EcuadorDocumento.cedula_valida?(value)
      record.errors.add(attribute, options[:message] || "no es una cédula ecuatoriana válida")
    end
  end
end
