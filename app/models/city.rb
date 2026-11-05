class City < ApplicationRecord
  belongs_to :province
  has_many :companies, dependent: :restrict_with_error

  before_validation { self.nombre = nombre.to_s.squish.presence }

  validates :nombre, presence: true, length: { maximum: 80 },
                     uniqueness: { scope: :province_id, case_sensitive: false }
end
