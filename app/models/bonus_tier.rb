# Escalón de bono definido por la empresa: "si un técnico participa y resuelve N casos en el mes, gana X % de su sueldo base".
# Solo se paga el escalón más alto alcanzado (no se acumulan).
class BonusTier < ApplicationRecord
  belongs_to :company
  has_many :bonus_payments, dependent: :nullify

  before_validation { self.nombre = nombre.to_s.squish.presence }

  validates :nombre, presence: true, length: { maximum: 40 }, uniqueness: { scope: :company_id, case_sensitive: false }
  validates :casos_minimos, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 500 },
                            uniqueness: { scope: :company_id }
  validates :porcentaje, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validate :porcentaje_crece_con_los_casos

  scope :de_mayor_a_menor, -> { order(casos_minimos: :desc) }

  # Dinero del bono para un sueldo base: porcentaje × sueldo. Ej.: 10 % de $500 = $50.
  def monto_para(sueldo_base)
    return 0 if sueldo_base.blank?

    (sueldo_base * porcentaje / 100).round(2)
  end

  private

  # Un escalón con más casos debe pagar un porcentaje mayor que cualquiera con menos casos; si no, no tendría sentido esforzarse.
  def porcentaje_crece_con_los_casos
    return if company_id.blank? || casos_minimos.blank? || porcentaje.blank?

    otros = BonusTier.where(company_id: company_id).where.not(id: id)
    menor = otros.where("casos_minimos < ? AND porcentaje >= ?", casos_minimos, porcentaje).first
    mayor = otros.where("casos_minimos > ? AND porcentaje <= ?", casos_minimos, porcentaje).first

    errors.add(:porcentaje, "debe ser mayor que el del escalón «#{menor.nombre}» (#{menor.casos_minimos} casos)") if menor
    errors.add(:porcentaje, "debe ser menor que el del escalón «#{mayor.nombre}» (#{mayor.casos_minimos} casos)") if mayor
  end
end
