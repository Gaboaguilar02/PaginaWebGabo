module ApplicationHelper
  # Enlace del menú superior; se marca como activo si la URL actual cae dentro de esa sección.
  def nav_link(texto, ruta)
    activo = ruta == admin_root_path ? request.path == ruta : request.path.start_with?(ruta)
    link_to texto, ruta, class: [ "topnav__link", ("is-active" if activo) ]
  end

  def badge(texto, tipo = :neutral)
    tag.span texto, class: "badge badge--#{tipo}"
  end

  def badge_estado_empresa(company)
    tipo = { "activa" => :ok, "pendiente" => :warn, "suspendida" => :danger }.fetch(company.status, :neutral)
    badge(company.status_label, tipo)
  end

  def badge_rol(user)
    tipo = { "admin" => :info, "empresa" => :warn, "tecnico" => :ok, "cliente" => :neutral }.fetch(user.role, :neutral)
    badge(user.role_label, tipo)
  end
end
