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
end

puts "Seeds listos: #{Province.count} provincias, #{City.count} ciudades, #{ApplianceType.count} electrodomésticos, " \
     "#{Company.count} empresas, #{User.count} usuarios."
