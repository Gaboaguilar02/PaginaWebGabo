# Escalón de bono definido por la empresa: "si un técnico resuelve N casos en el mes, gana $X".
# Solo se paga el escalón más alto alcanzado (no se acumulan).
class BonusTier < ApplicationRecord
  MAX_MONTO = 100_000

  belongs_to :company
  has_many :bonus_payments, dependent: :nullify

  before_validation { self.nombre = nombre.to_s.squish.presence }

  validates :nombre, presence: true, length: { maximum: 40 }, uniqueness: { scope: :company_id, case_sensitive: false }
  validates :casos_minimos, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 500 },
                            uniqueness: { scope: :company_id }
  validates :monto, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: MAX_MONTO }
  validate :monto_crece_con_los_casos

  scope :de_mayor_a_menor, -> { order(casos_minimos: :desc) }

  # Escalón más alto alcanzado por una empresa con esa cantidad de casos resueltos (nil si no llega a ninguno).
  def self.alcanzado(company, casos)
    where(company_id: company.id).where("casos_minimos <= ?", casos).order(casos_minimos: :desc).first
  end

  private

  # Un escalón con más casos debe pagar más que cualquiera con menos casos; si no, no tendría sentido esforzarse.
  def monto_crece_con_los_casos
    return if company_id.blank? || casos_minimos.blank? || monto.blank?

    otros = BonusTier.where(company_id: company_id).where.not(id: id)
    menor = otros.where("casos_minimos < ? AND monto >= ?", casos_minimos, monto).first
    mayor = otros.where("casos_minimos > ? AND monto <= ?", casos_minimos, monto).first

    errors.add(:monto, "debe ser mayor que el del escalón «#{menor.nombre}» (#{menor.casos_minimos} casos)") if menor
    errors.add(:monto, "debe ser menor que el del escalón «#{mayor.nombre}» (#{mayor.casos_minimos} casos)") if mayor
  end
end
