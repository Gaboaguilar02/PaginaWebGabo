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
  validate :empresa_segun_rol

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

  def empresa_segun_rol
    if ROLES_CON_EMPRESA.include?(role) && company.nil?
      errors.add(:company_id, "es obligatoria para usuarios con rol #{ROLE_LABELS[role].downcase}")
    elsif ROLES.include?(role) && !ROLES_CON_EMPRESA.include?(role) && company.present?
      errors.add(:company_id, "solo aplica a usuarios con rol empresa o técnico")
    end
  end
end
