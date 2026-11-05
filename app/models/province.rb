class Province < ApplicationRecord
  has_many :cities, dependent: :restrict_with_error

  before_validation { self.nombre = nombre.to_s.squish.presence }

  validates :nombre, presence: true, length: { maximum: 80 }, uniqueness: { case_sensitive: false }
end
