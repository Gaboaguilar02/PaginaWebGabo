class Company < ApplicationRecord
  STATUSES = %w[ pendiente activa suspendida ].freeze
  STATUS_LABELS = { "pendiente" => "Pendiente", "activa" => "Activa", "suspendida" => "Suspendida" }.freeze

  belongs_to :city
  has_one :province, through: :city
  has_many :company_appliance_types, dependent: :destroy
  has_many :appliance_types, through: :company_appliance_types
  has_many :users, dependent: :restrict_with_error
  has_many :repair_cases, dependent: :restrict_with_error
  has_many :bonus_payments, dependent: :restrict_with_error
  has_many :bonus_tiers, dependent: :destroy

  before_validation :normalizar_campos

  validates :nombre, presence: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false }
  # Dato sensible: el RUC se valida en el servidor (algoritmo oficial) antes de guardar.
  validates :ruc, presence: true, uniqueness: true, ruc: true
  validates :telefono, format: { with: /\A[0-9+\-\s()]{7,20}\z/, message: "solo admite números, espacios, + - ( ) (7 a 20 caracteres)" },
                       allow_blank: true
  validates :descripcion, length: { maximum: 1000 }
  validates :status, inclusion: { in: STATUSES }
  # Requisitos para participar en el ranking y cobrar bono (cada empresa los ajusta; por defecto 4,2 y 20 casos).
  validates :min_calificacion, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :min_casos_participar, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 500 }
  validate :activa_requiere_electrodomesticos

  scope :activas, -> { where(status: "activa") }

  def activa?
    status == "activa"
  end

  def status_label
    STATUS_LABELS.fetch(status, status)
  end

  # Empresas que pueden atender un servicio: activas, de esa ciudad y que reparan ese electrodoméstico.
  def self.disponibles_para(city_id:, appliance_type_id:)
    return none if city_id.blank? || appliance_type_id.blank?

    activas.where(city_id: city_id)
           .where(id: CompanyApplianceType.where(appliance_type_id: appliance_type_id).select(:company_id))
           .order(:nombre)
  end

  def etiqueta_con_reputacion
    reviews_count.zero? ? "#{nombre} · sin calificaciones" : "#{nombre} · ★ #{rating_promedio} (#{reviews_count})"
  end

  # Reputación de la empresa = promedio de las calificaciones que dieron los clientes.
  def recalcular_reputacion!
    calificados = repair_cases.where.not(calificacion: nil)
    update_columns(rating_promedio: (calificados.average(:calificacion) || 0).round(2), reviews_count: calificados.count)
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
