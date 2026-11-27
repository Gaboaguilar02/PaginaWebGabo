module ApplicationHelper
  # Enlace del menú superior; se marca como activo si la URL actual cae dentro de esa sección.
  def nav_link(texto, ruta, activo: nil)
    activo = ([ admin_root_path, empresa_root_path, tecnico_root_path ].include?(ruta) ? request.path == ruta : request.path.start_with?(ruta)) if activo.nil?
    link_to texto, ruta, class: [ "topnav__link", ("is-active" if activo) ]
  end

  def badge(texto, tipo = :neutral)
    tag.span texto, class: "badge badge--#{tipo}"
  end

  def badge_estado_empresa(company)
    tipo = { "activa" => :ok, "pendiente" => :warn, "suspendida" => :danger }.fetch(company.status, :neutral)
    badge(company.status_label, tipo)
  end

  def badge_estado_caso(repair_case)
    tipo = case repair_case.status
    when "resuelta" then :ok
    when "cancelada", "rechazada" then :danger
    when "solicitada" then :warn
    else :info
    end
    badge(repair_case.status_label, tipo)
  end

  # Estrellas de una calificación (1 a 5), p. ej. "★★★★☆".
  def estrellas(puntaje)
    "★" * puntaje.to_i + "☆" * (5 - puntaje.to_i)
  end

  def badge_estado_caso(repair_case)
    tipo = case repair_case.status
    when "resuelta" then :ok
    when "cancelada", "rechazada" then :danger
    when "solicitada" then :warn
    else :info
    end
    badge(repair_case.status_label, tipo)
  end

  # Estrellas de una calificación (1 a 5), p. ej. "★★★★☆".
  def estrellas(puntaje)
    "★" * puntaje.to_i + "☆" * (5 - puntaje.to_i)
  end

  # Calificación con dos decimales y coma: 4,75
  def nota(valor)
    valor.nil? ? "—" : number_with_precision(valor, precision: 2)
  end

  # Porcentaje sin ceros de sobra: "10 %", "7,5 %"
  def porcentaje(valor)
    "#{number_with_precision(valor, precision: 2, strip_insignificant_zeros: true)} %"
  end

  # Posición en el ranking; los tres primeros llevan medalla de color.
  def posicion(numero)
    clase = { 1 => "oro", 2 => "plata", 3 => "bronce" }.fetch(numero, "normal")
    tag.span numero, class: "pos pos--#{clase}"
  end

  def badge_rol(user)
    tipo = { "admin" => :info, "empresa" => :warn, "tecnico" => :ok, "cliente" => :neutral }.fetch(user.role, :neutral)
    badge(user.role_label, tipo)
  end
end
