class ApplianceType < ApplicationRecord
  has_many :company_appliance_types, dependent: :restrict_with_error
  has_many :companies, through: :company_appliance_types

  before_validation { self.nombre = nombre.to_s.squish.presence }

  validates :nombre, presence: true, length: { maximum: 60 }, uniqueness: { case_sensitive: false }

  scope :activos, -> { where(activo: true) }
end
