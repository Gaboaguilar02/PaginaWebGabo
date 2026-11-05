class Company < ApplicationRecord
  STATUSES = %w[ pendiente activa suspendida ].freeze
  STATUS_LABELS = { "pendiente" => "Pendiente", "activa" => "Activa", "suspendida" => "Suspendida" }.freeze

  belongs_to :city
  has_one :province, through: :city
  has_many :company_appliance_types, dependent: :destroy
  has_many :appliance_types, through: :company_appliance_types
  has_many :users, dependent: :restrict_with_error

  before_validation :normalizar_campos

  validates :nombre, presence: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false }
  # Dato sensible: el RUC se valida en el servidor (algoritmo oficial) antes de guardar.
  validates :ruc, presence: true, uniqueness: true, ruc: true
  validates :telefono, format: { with: /\A[0-9+\-\s()]{7,20}\z/, message: "solo admite números, espacios, + - ( ) (7 a 20 caracteres)" },
                       allow_blank: true
  validates :descripcion, length: { maximum: 1000 }
  validates :status, inclusion: { in: STATUSES }
  validate :activa_requiere_electrodomesticos

  scope :activas, -> { where(status: "activa") }

  def activa?
    status == "activa"
  end

  def status_label
    STATUS_LABELS.fetch(status, status)
  end

  private

  def normalizar_campos
    self.nombre = nombre.to_s.squish.presence
    self.ruc = ruc.to_s.gsub(/\s+/, "").presence
    self.telefono = telefono.to_s.squish.presence
    self.direccion = direccion.to_s.squish.presence
  end

  def activa_requiere_electrodomesticos
    return unless activa? && appliance_types.empty?

    errors.add(:base, "Una empresa activa debe reparar al menos un tipo de electrodoméstico")
  end
end
