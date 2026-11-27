# Caso de reparación: un cliente pide el servicio a una empresa para un electrodoméstico.
# La empresa lo acepta y asigna un técnico; el técnico lo resuelve y el cliente califica (feedback).
class RepairCase < ApplicationRecord
  STATUSES = %w[ solicitada aceptada asignada en_camino en_reparacion resuelta cancelada rechazada ].freeze
  STATUS_LABELS = {
    "solicitada" => "Solicitada",
    "aceptada" => "Aceptada por la empresa",
    "asignada" => "Técnico asignado",
    "en_camino" => "Técnico en camino",
    "en_reparacion" => "En reparación",
    "resuelta" => "Resuelta",
    "cancelada" => "Cancelada",
    "rechazada" => "Rechazada por la empresa"
  }.freeze
  # Pasos del avance normal del caso (la línea de tiempo que ve el cliente).
  FLUJO = %w[ solicitada aceptada asignada en_camino en_reparacion resuelta ].freeze
  CERRADOS = %w[ resuelta cancelada rechazada ].freeze
  CANCELABLES = %w[ solicitada aceptada ].freeze

  EN_ATENCION = %w[ asignada en_camino en_reparacion ].freeze
  MAX_EVIDENCIAS_TECNICO = 6
  MAX_EVIDENCIAS = 4
  MAX_TAMANO_EVIDENCIA = 5.megabytes

  belongs_to :client, class_name: "User"
  belongs_to :company
  belongs_to :technician, class_name: "User", optional: true
  belongs_to :appliance_type
  belongs_to :city

  has_many_attached :evidencias          # fotos del daño que sube el cliente al pedir el servicio
  has_many_attached :evidencias_tecnico  # fotos del trabajo que sube el técnico durante la reparación

  before_validation :normalizar_campos

  validates :falla, presence: true, length: { in: 10..1000 }
  validates :direccion, presence: true, length: { maximum: 150 }
  validates :status, inclusion: { in: STATUSES }
  validates :calificacion, inclusion: { in: 1..5 }, allow_nil: true
  validates :comentario_feedback, length: { maximum: 500 }
  validate :cliente_valido
  validate :empresa_puede_atender
  validates :motivo_rechazo, length: { maximum: 200 }
  validates :informe_tecnico, length: { maximum: 500 }
  validate :tecnico_de_la_empresa
  validate :tecnico_requerido_desde_asignacion
  validate :feedback_solo_si_resuelta
  validate :evidencias_validas

  scope :recientes, -> { order(created_at: :desc) }
  scope :activos, -> { where.not(status: CERRADOS) }
  scope :resueltos, -> { where(status: "resuelta") }
  scope :pendientes_de_calificar, -> { resueltos.where(calificacion: nil) }

  def status_label
    STATUS_LABELS.fetch(status, status)
  end

  def activo?
    !CERRADOS.include?(status)
  end

  def cancelable?
    CANCELABLES.include?(status)
  end

  def puede_calificar?
    status == "resuelta" && calificacion.nil?
  end

  def calificado?
    calificacion.present?
  end

  # Posición (0..5) dentro del flujo normal; nil si el caso fue cancelado o rechazado.
  def paso_actual
    FLUJO.index(status)
  end

  def cancelar!
    return false unless cancelable?

    update(status: "cancelada")
  end

  # ---- Acciones de la empresa -------------------------------------------------

  def aceptable?
    status == "solicitada"
  end

  def asignable?
    %w[ aceptada asignada ].include?(status)
  end

  def aceptar!
    return false unless aceptable?

    update(status: "aceptada")
  end

  def rechazar!(motivo)
    return false unless aceptable?

    if motivo.to_s.squish.blank?
      errors.add(:motivo_rechazo, "es obligatorio para rechazar una solicitud")
      return false
    end

    update(status: "rechazada", motivo_rechazo: motivo.to_s.squish.first(200))
  end

  # Asigna (o reasigna, mientras el técnico aún no sale) el técnico que atenderá el caso.
  def asignar!(tecnico)
    return false unless asignable?

    update(technician: tecnico, status: "asignada")
  end

  # ---- Acciones del técnico ---------------------------------------------------

  def en_atencion?
    EN_ATENCION.include?(status)
  end

  # asignada -> en camino
  def salir!
    avanzar!("asignada", "en_camino")
  end

  # en camino -> en reparación
  def iniciar_reparacion!
    avanzar!("en_camino", "en_reparacion")
  end

  # en reparación -> resuelta. El técnico debe dejar un informe de lo que hizo; este cierre es lo que cuenta para el ranking.
  def resolver!(informe)
    return false unless status == "en_reparacion"

    informe = informe.to_s.squish
    if informe.length < 10
      errors.add(:informe_tecnico, "debe describir la reparación (mínimo 10 caracteres)")
      return false
    end

    update(status: "resuelta", informe_tecnico: informe, resuelta_at: Time.current)
  end

  # Registra el feedback del cliente y actualiza la reputación de la empresa.
  def calificar!(puntaje, comentario)
    return false unless puede_calificar?

    transaction do
      update!(calificacion: puntaje, comentario_feedback: comentario, feedback_at: Time.current)
      company.recalcular_reputacion!
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  def avanzar!(desde, hacia)
    return false unless status == desde

    update(status: hacia)
  end

  def normalizar_campos
    self.falla = falla.to_s.squish.presence
    self.direccion = direccion.to_s.squish.presence
    self.comentario_feedback = comentario_feedback.to_s.squish.presence
  end

  def cliente_valido
    errors.add(:client, "debe tener rol cliente") if client && !client.cliente?
  end

  # La empresa debe estar activa, estar en la ciudad del servicio y reparar ese electrodoméstico.
  def empresa_puede_atender
    return unless company && (new_record? || will_save_change_to_company_id? || will_save_change_to_city_id? || will_save_change_to_appliance_type_id?)

    errors.add(:company, "no está activa") unless company.activa?
    errors.add(:company, "no atiende en la ciudad seleccionada") if city && company.city_id != city_id
    return unless appliance_type

    errors.add(:appliance_type, "no es reparado por la empresa elegida") unless company.appliance_types.exists?(appliance_type.id)
    errors.add(:appliance_type, "no está disponible en el catálogo") unless appliance_type.activo?
  end

  def tecnico_de_la_empresa
    return unless technician

    errors.add(:technician, "debe ser un técnico de la empresa") unless technician.tecnico? && technician.company_id == company_id
  end

  # Desde que se asigna el caso hasta que se resuelve, siempre hay un técnico responsable.
  def tecnico_requerido_desde_asignacion
    return unless %w[ asignada en_camino en_reparacion resuelta ].include?(status) && technician.nil?

    errors.add(:technician, "es obligatorio una vez asignado el caso")
  end

  def feedback_solo_si_resuelta
    return unless calificacion.present? || comentario_feedback.present?

    errors.add(:base, "Solo se puede calificar un caso resuelto") unless status == "resuelta"
  end

  def evidencias_validas
    validar_imagenes(:evidencias, MAX_EVIDENCIAS)
    validar_imagenes(:evidencias_tecnico, MAX_EVIDENCIAS_TECNICO)
  end

  def validar_imagenes(nombre, maximo)
    adjuntos = public_send(nombre)
    return unless adjuntos.attached?

    errors.add(nombre, "admite máximo #{maximo} imágenes") if adjuntos.size > maximo
    adjuntos.each do |adjunto|
      errors.add(nombre, "solo admite imágenes (JPG, PNG o WEBP)") unless adjunto.blob.content_type.in?(%w[ image/jpeg image/png image/webp ])
      errors.add(nombre, "no puede pesar más de 5 MB por imagen") if adjunto.blob.byte_size > MAX_TAMANO_EVIDENCIA
    end
  end
end
