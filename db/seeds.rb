# Datos iniciales. Es idempotente: se puede ejecutar varias veces sin duplicar registros.
#
# Variables de entorno opcionales:
#   ADMIN_PASSWORD  contraseña del usuario admin (por defecto "admin123": cámbiala en producción)
#   DEMO_PASSWORD   contraseña de los usuarios de demostración (por defecto "demo123")
#   SEED_DEMO       "false" para no crear empresas ni usuarios de demostración

# ---------------------------------------------------------------- Ubicaciones
UBICACIONES = {
  "Azuay" => [ "Cuenca", "Gualaceo", "Paute", "Sígsig" ],
  "Bolívar" => [ "Guaranda", "San Miguel", "Chillanes" ],
  "Cañar" => [ "Azogues", "Biblián", "La Troncal" ],
  "Carchi" => [ "Tulcán", "San Gabriel", "Mira" ],
  "Chimborazo" => [ "Riobamba", "Guano", "Alausí" ],
  "Cotopaxi" => [ "Latacunga", "Salcedo", "La Maná" ],
  "El Oro" => [ "Machala", "Pasaje", "Santa Rosa", "Huaquillas" ],
  "Esmeraldas" => [ "Esmeraldas", "Atacames", "Quinindé" ],
  "Galápagos" => [ "Puerto Ayora", "Puerto Baquerizo Moreno", "Puerto Villamil" ],
  "Guayas" => [ "Guayaquil", "Daule", "Durán", "Milagro", "Samborondón" ],
  "Imbabura" => [ "Ibarra", "Otavalo", "Cotacachi", "Atuntaqui" ],
  "Loja" => [ "Loja", "Catamayo", "Macará" ],
  "Los Ríos" => [ "Babahoyo", "Quevedo", "Ventanas" ],
  "Manabí" => [ "Portoviejo", "Manta", "Chone", "Montecristi" ],
  "Morona Santiago" => [ "Macas", "Sucúa", "Gualaquiza" ],
  "Napo" => [ "Tena", "Archidona" ],
  "Orellana" => [ "Francisco de Orellana (Coca)", "La Joya de los Sachas" ],
  "Pastaza" => [ "Puyo", "Mera" ],
  "Pichincha" => [ "Quito", "Cayambe", "Machachi", "Sangolquí" ],
  "Santa Elena" => [ "Santa Elena", "La Libertad", "Salinas" ],
  "Santo Domingo de los Tsáchilas" => [ "Santo Domingo" ],
  "Sucumbíos" => [ "Nueva Loja", "Shushufindi" ],
  "Tungurahua" => [ "Ambato", "Baños de Agua Santa", "Pelileo" ],
  "Zamora Chinchipe" => [ "Zamora", "Yantzaza" ]
}.freeze

UBICACIONES.each do |provincia, ciudades|
  province = Province.find_or_create_by!(nombre: provincia)
  ciudades.each { |ciudad| City.find_or_create_by!(province: province, nombre: ciudad) }
end

# ------------------------------------------------- Catálogo de electrodomésticos
[ "Lavadora", "Secadora", "Refrigerador", "Cocina", "Lavavajillas", "Microondas", "Congelador" ].each do |nombre|
  ApplianceType.find_or_create_by!(nombre: nombre)
end

# ------------------------------------------------------------ Usuario administrador
# La cédula del administrador es un número de prueba con dígito verificador correcto.
admin = User.find_or_initialize_by(username: "admin")
admin.assign_attributes(nombre_completo: "Administrador del sistema", cedula: "1700000019", role: "admin", activo: true)
admin.password = ENV.fetch("ADMIN_PASSWORD", "admin123") if admin.new_record?
admin.save!

# ------------------------------------------------------- Datos de demostración
unless ENV["SEED_DEMO"] == "false"
  password = ENV.fetch("DEMO_PASSWORD", "demo123")
  quito = City.find_by!(nombre: "Quito")
  guayaquil = City.find_by!(nombre: "Guayaquil")

  tecnifrio = Company.find_or_initialize_by(ruc: "1790001237001")
  tecnifrio.assign_attributes(
    nombre: "TecniFrío S.A.", city: quito, telefono: "022345678", direccion: "Av. Amazonas N24-15",
    descripcion: "Reparación de refrigeradores, lavadoras y secadoras a domicilio.", status: "activa"
  )
  tecnifrio.appliance_types = ApplianceType.where(nombre: [ "Lavadora", "Refrigerador", "Secadora" ]).to_a if tecnifrio.new_record?
  tecnifrio.save!

  hogarfix = Company.find_or_initialize_by(ruc: "0990000018001")
  hogarfix.assign_attributes(
    nombre: "HogarFix Cía. Ltda.", city: guayaquil, telefono: "042567890", direccion: "Av. 9 de Octubre 1200",
    descripcion: "Servicio técnico de línea blanca en Guayaquil.", status: "pendiente"
  )
  hogarfix.appliance_types = ApplianceType.where(nombre: [ "Cocina", "Lavavajillas" ]).to_a if hogarfix.new_record?
  hogarfix.save!

  [
    { username: "empresa1", nombre_completo: "Marta Ruiz (TecniFrío)", cedula: "0900000076", role: "empresa", company: tecnifrio },
    { username: "tecnico1", nombre_completo: "Juan Pérez", cedula: "0100000025", role: "tecnico", company: tecnifrio },
    { username: "cliente1", nombre_completo: "Ana Torres", cedula: "1712345675", role: "cliente", company: nil }
  ].each do |datos|
    usuario = User.find_or_initialize_by(username: datos[:username])
    usuario.assign_attributes(datos.merge(activo: true))
    usuario.password = password if usuario.new_record?
    usuario.save!
  end

  # Casos de reparación de ejemplo para el cliente demo: uno en cada etapa del flujo,
  # para recorrer la perspectiva del cliente sin esperar a que empresa y técnico los muevan.
  cliente = User.find_by!(username: "cliente1")
  tecnico = User.find_by!(username: "tecnico1")
  [
    { falla: "La lavadora no centrifuga y hace un ruido fuerte al empezar el ciclo.", tipo: "Lavadora",
      status: "en_reparacion", technician: tecnico, creado: 2.days.ago },
    { falla: "El refrigerador enfría poco y la puerta no sella bien.", tipo: "Refrigerador",
      status: "resuelta", technician: tecnico, creado: 4.days.ago, resuelta: 2.days.ago },
    { falla: "La secadora se detiene a mitad del ciclo y huele a quemado.", tipo: "Secadora",
      status: "solicitada", technician: nil, creado: 3.hours.ago },
    { falla: "La lavadora pierde agua por la parte inferior.", tipo: "Lavadora",
      status: "resuelta", technician: tecnico, creado: 20.days.ago, resuelta: 18.days.ago,
      calificacion: 5, comentario: "Llegó puntual, explicó la falla y la dejó funcionando." }
  ].each do |datos|
    caso = RepairCase.find_or_initialize_by(client: cliente, falla: datos[:falla])
    next unless caso.new_record?

    caso.assign_attributes(
      company: tecnifrio, city: quito, direccion: "Av. República del Salvador N34-183", appliance_type: ApplianceType.find_by!(nombre: datos[:tipo]),
      status: datos[:status], technician: datos[:technician], created_at: datos[:creado], resuelta_at: datos[:resuelta],
      calificacion: datos[:calificacion], comentario_feedback: datos[:comentario], feedback_at: (datos[:resuelta] if datos[:calificacion])
    )
    caso.save!
  end
  # ---- Datos para el panel de la empresa: más técnicos, historial de casos resueltos, escalones y un pago ----
  [
    { username: "tecnico2", nombre_completo: "Carlos Mena", cedula: "0200000016", role: "tecnico", company: tecnifrio },
    { username: "tecnico3", nombre_completo: "Lucía Vera", cedula: "0300000015", role: "tecnico", company: tecnifrio },
    { username: "cliente2", nombre_completo: "Luis Andrade", cedula: "1712345683", role: "cliente", company: nil },
    { username: "cliente3", nombre_completo: "Sofía Paredes", cedula: "1723456784", role: "cliente", company: nil }
  ].each do |datos|
    usuario = User.find_or_initialize_by(username: datos[:username])
    usuario.assign_attributes(datos.merge(activo: true))
    usuario.password = password if usuario.new_record?
    usuario.save!
  end

  tecnico1 = tecnico
  tecnico2 = User.find_by!(username: "tecnico2")
  tecnico3 = User.find_by!(username: "tecnico3")
  clientes = [ User.find_by!(username: "cliente2"), User.find_by!(username: "cliente3") ]
  equipos = ApplianceType.where(nombre: [ "Lavadora", "Refrigerador", "Secadora" ]).order(:nombre).to_a

  # Escalones de bono de TecniFrío (con más casos, más dinero; se paga solo el más alto alcanzado).
  [ [ "Bronce", 5, 30 ], [ "Plata", 10, 60 ], [ "Oro", 15, 100 ] ].each do |nombre, casos, monto|
    BonusTier.find_or_create_by!(company: tecnifrio, casos_minimos: casos) { |escalon| escalon.assign_attributes(nombre: nombre, monto: monto) }
  end

  # Casos resueltos de ejemplo: mes anterior (cerrado, para registrar pagos) y mes actual (en curso).
  mes_actual = Date.current.beginning_of_month.in_time_zone
  mes_anterior = (Date.current.beginning_of_month - 1.month).in_time_zone
  notas = [ 5, 5, 4, 5, 4, 5, 3, 5, 4, 5, 5, 4 ]
  historial = [
    [ tecnico1, mes_anterior, 12, "anterior" ], [ tecnico2, mes_anterior, 7, "anterior" ], [ tecnico3, mes_anterior, 4, "anterior" ],
    [ tecnico2, mes_actual, 5, "actual" ], [ tecnico1, mes_actual, 3, "actual" ], [ tecnico3, mes_actual, 2, "actual" ]
  ]
  historial.each do |tecnico, mes, cantidad, etiqueta|
    cantidad.times do |i|
      falla = "[demo] Reparación #{i + 1} de #{tecnico.nombre_completo} (mes #{etiqueta})"
      caso = RepairCase.find_or_initialize_by(client: clientes[i % 2], falla: falla)
      next unless caso.new_record?

      resuelta = mes + (i + 1).days + 9.hours
      resuelta = Time.current - 1.hour if resuelta > Time.current
      caso.assign_attributes(
        company: tecnifrio, city: quito, direccion: "Av. 6 de Diciembre N31-120", appliance_type: equipos[i % equipos.size],
        status: "resuelta", technician: tecnico, created_at: resuelta - 1.day, resuelta_at: resuelta,
        calificacion: notas[(i + tecnico.id) % notas.size], feedback_at: resuelta + 3.hours,
        comentario_feedback: [ "Muy buen servicio", "Puntual y amable", "Resolvió el problema", nil ][i % 4]
      )
      caso.save!
    end
  end

  # Solicitudes que esperan acción de la empresa: una por aceptar y una aceptada por asignar.
  [
    { cliente: clientes[0], falla: "El refrigerador hace ruido y no enfría la parte de abajo.", tipo: "Refrigerador", status: "solicitada", creado: 1.hour.ago },
    { cliente: clientes[1], falla: "La lavadora no desagua al terminar el lavado.", tipo: "Lavadora", status: "aceptada", creado: 5.hours.ago }
  ].each do |datos|
    caso = RepairCase.find_or_initialize_by(client: datos[:cliente], falla: datos[:falla])
    next unless caso.new_record?

    caso.assign_attributes(company: tecnifrio, city: quito, direccion: "Calle Mariana de Jesús y Pradera", appliance_type: ApplianceType.find_by!(nombre: datos[:tipo]),
                           status: datos[:status], created_at: datos[:creado])
    caso.save!
  end

  # Un caso ya asignado a Juan: listo para que el técnico lo recorra (salir -> iniciar -> resolver) en la demo.
  falla_asignada = "El refrigerador congela los alimentos de la parte superior y hace ruido."
  unless RepairCase.exists?(client: clientes[0], falla: falla_asignada)
    RepairCase.create!(client: clientes[0], company: tecnifrio, city: quito, direccion: "Av. Eloy Alfaro N35-12", appliance_type: ApplianceType.find_by!(nombre: "Refrigerador"),
                       falla: falla_asignada, status: "asignada", technician: tecnico1, created_at: 3.hours.ago)
  end

  # Informe del técnico en los casos resueltos de ejemplo
  RepairCase.resueltos.where(informe_tecnico: nil).update_all(informe_tecnico: "Se diagnosticó la falla, se reparó y se probó el equipo junto al cliente.")

  # Un pago ya registrado del mes anterior (Plata para Juan); el de Carlos (Bronce) queda pendiente para mostrar cómo se registra.
  if BonusPayment.where(company: tecnifrio, technician: tecnico1, periodo: mes_anterior.to_date).none?
    BonusPayment.registrar(company: tecnifrio, technician: tecnico1, periodo: mes_anterior.to_date, por: User.find_by!(username: "empresa1"),
                           nota: "Pagado con la nómina del mes")
  end

  tecnifrio.recalcular_reputacion!
end

puts "Seeds listos: #{Province.count} provincias, #{City.count} ciudades, #{ApplianceType.count} electrodomésticos, " \
     "#{Company.count} empresas, #{User.count} usuarios."
