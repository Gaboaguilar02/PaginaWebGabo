class User < ApplicationRecord
  ROLES = %w[ admin empresa tecnico cliente ].freeze
  ROLE_LABELS = {
    "admin" => "Administrador",
    "empresa" => "Empresa",
    "tecnico" => "Técnico",
    "cliente" => "Cliente"
  }.freeze
  ROLES_CON_EMPRESA = %w[ empresa tecnico ].freeze

  has_secure_password

  belongs_to :company, optional: true
  has_many :solicitudes, class_name: "RepairCase", foreign_key: :client_id, inverse_of: :client, dependent: :restrict_with_error
  has_many :casos_asignados, class_name: "RepairCase", foreign_key: :technician_id, inverse_of: :technician, dependent: :restrict_with_error
  has_many :bonos_recibidos, class_name: "BonusPayment", foreign_key: :technician_id, inverse_of: :technician, dependent: :restrict_with_error
  has_many :bonos_registrados, class_name: "BonusPayment", foreign_key: :registrado_por_id, inverse_of: :registrado_por, dependent: :restrict_with_error

  before_validation :normalizar_campos

  validates :username, presence: true,
                       length: { in: 3..30 },
                       format: { with: /\A[a-z0-9_.]+\z/, message: "solo admite letras minúsculas, números, punto y guion bajo" },
                       uniqueness: { case_sensitive: false }
  validates :nombre_completo, presence: true, length: { maximum: 100 }
  # Dato sensible: la cédula se valida en el servidor (módulo 10) antes de guardar.
  validates :cedula, presence: true, uniqueness: true, cedula: true
  validates :role, inclusion: { in: ROLES }
  validates :password, length: { minimum: 6 }, allow_nil: true
  # Sueldo base mensual del técnico (lo registra su empresa): es la base del bono en porcentaje.
  validates :sueldo_base, numericality: { greater_than: 0, less_than_or_equal_to: 100_000 }, allow_nil: true
  validate :empresa_segun_rol
  validate :sueldo_solo_para_tecnicos

  scope :activos, -> { where(activo: true) }

  ROLES.each do |nombre_rol|
    define_method("#{nombre_rol}?") { role == nombre_rol }
  end

  def role_label
    ROLE_LABELS.fetch(role, role)
  end

  private

  def normalizar_campos
    self.username = username.to_s.strip.downcase.presence
    self.nombre_completo = nombre_completo.to_s.squish.presence
    self.cedula = cedula.to_s.gsub(/\s+/, "").presence
  end

  def sueldo_solo_para_tecnicos
    errors.add(:sueldo_base, "solo aplica a usuarios con rol técnico") if sueldo_base.present? && !tecnico?
  end

  def empresa_segun_rol
    if ROLES_CON_EMPRESA.include?(role) && company.nil?
      errors.add(:company_id, "es obligatoria para usuarios con rol #{ROLE_LABELS[role].downcase}")
    elsif ROLES.include?(role) && !ROLES_CON_EMPRESA.include?(role) && company.present?
      errors.add(:company_id, "solo aplica a usuarios con rol empresa o técnico")
    end
  end
end
