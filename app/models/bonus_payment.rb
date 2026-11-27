# Registro del pago de un bono mensual a un técnico. La plataforma NO mueve dinero: solo deja constancia
# de que la empresa pagó el escalón más alto que el técnico alcanzó en ese período (por casos resueltos).
class BonusPayment < ApplicationRecord
  belongs_to :company
  belongs_to :technician, class_name: "User"
  belongs_to :registrado_por, class_name: "User"
  belongs_to :bonus_tier, optional: true

  before_validation :normalizar_campos

  validates :periodo, presence: true, uniqueness: { scope: :technician_id, message: "ya tiene un pago registrado para este técnico" }
  validates :tier_nombre, :pagado_at, presence: true
  validates :casos_resueltos, :casos_minimos, numericality: { only_integer: true, greater_than: 0 }
  validates :monto, numericality: { greater_than: 0 }
  validates :nota, length: { maximum: 200 }
  validate :periodo_cerrado
  validate :tecnico_de_la_empresa

  scope :recientes, -> { order(periodo: :desc, pagado_at: :desc) }

  # Registra el pago del período para un técnico, calculando el escalón con los casos realmente resueltos.
  # Devuelve el pago (guardado, o con errores si no corresponde pagar).
  def self.registrar(company:, technician:, periodo:, por:, nota: nil)
    periodo = periodo.to_date.beginning_of_month
    fila = MonthlyRanking.new(company, periodo).fila_de(technician)
    tier = fila&.tier

    pago = new(company: company, technician: technician, registrado_por: por, periodo: periodo, nota: nota, pagado_at: Time.current)
    if tier.nil?
      pago.errors.add(:base, "#{technician.nombre_completo} no alcanzó ningún escalón de bono en este período")
      return pago
    end

    pago.assign_attributes(bonus_tier: tier, tier_nombre: tier.nombre, casos_minimos: tier.casos_minimos,
                           casos_resueltos: fila.resueltos, monto: tier.monto)
    pago.save
    pago
  end

  private

  def normalizar_campos
    self.nota = nota.to_s.squish.presence
  end

  # El bono se paga con el mes ya cerrado: durante el mes los casos todavía pueden cambiar.
  def periodo_cerrado
    return if periodo.blank?

    errors.add(:periodo, "todavía no ha terminado: el bono se registra cuando el mes cierra") if periodo >= Date.current.beginning_of_month
  end

  def tecnico_de_la_empresa
    return unless technician

    errors.add(:technician, "debe ser un técnico de la empresa") unless technician.tecnico? && technician.company_id == company_id
  end
end
