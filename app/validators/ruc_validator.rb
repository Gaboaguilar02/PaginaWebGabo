# Uso: validates :ruc, ruc: true
# Valida en el servidor (back-end) que el RUC ecuatoriano sea correcto.
class RucValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    unless EcuadorDocumento.ruc_valido?(value)
      record.errors.add(attribute, options[:message] || "no es un RUC ecuatoriano válido")
    end
  end
end
