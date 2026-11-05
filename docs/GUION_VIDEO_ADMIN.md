# Guion del video: administración del core (máx. 3 minutos)

Graba con Loom o YouTube **la URL desplegada**. Cierra sesión antes de empezar. Haz una prueba corta y cronométrala.

## Antes de grabar
- Sesión cerrada, servidor/URL abiertos, datos de `db:seed` cargados.
- Dos pestañas: la app y VS Code (con `app/validators/ecuador_documento.rb` abierto).
- Ten a mano estos datos:

| Dato | Valor |
|------|-------|
| RUC **inválido** | `1790001238001` |
| RUC **válido** | `1791234561001` |
| Cédula **inválida** | `1710034066` |
| Cédula **válida** | `1710034065` |

---

## 1. Qué es y por qué alimenta el core (0:00 – 0:20)
> "Hola, soy **[tu nombre]**. Mi proyecto es una plataforma de servicios de línea blanca a domicilio. Su core es medir el desempeño de los técnicos con un ranking por casos resueltos y bonos escalonados. Para que eso funcione, alguien debe cargar las empresas, los técnicos, el catálogo y las ubicaciones: eso es esta administración."

**(Muestra el README o el diagrama ER unos segundos.)**

## 2. Seguridad: solo el admin (0:20 – 0:40)
> "Sin sesión, `/admin` me manda al login. Y si entro como cliente, tampoco puedo: solo el rol administrador."

**(Abre `/admin/companies` sin sesión → login. Inicia con `cliente1` / demo123, abre `/admin` → "No tienes permisos". Cierra sesión y entra con `admin`.)**

## 3. Panel y catálogos (0:40 – 1:00)
> "Este es el panel con los indicadores. El administrador mantiene el catálogo de electrodomésticos, las provincias y las ciudades."

**(Recorre Panel → Electrodomésticos → Provincias → Ciudades. Crea una ciudad eligiendo la provincia **de una lista**.)**

## 4. Dropdown dependiente (1:00 – 1:40)
> "Al crear una empresa no escribo ningún id. Elijo la **provincia** y el dropdown de **ciudades** se carga solo con las ciudades de esa provincia. Si cambio de provincia, la lista cambia. Marco los electrodomésticos que repara con casillas."

**(Empresas → Nueva empresa. Elige Pichincha → muestra ciudades; cambia a Guayas → cambian. Marca electrodomésticos.)**

> "La provincia ni siquiera se guarda: se deduce de la ciudad, así que no puede haber datos incoherentes."

## 5. Validación en el back-end (1:40 – 2:30)
> "El RUC es un dato sensible y se valida en el **servidor**, no solo en el navegador. Escribo un RUC con el dígito verificador mal."

**(Escribe `1790001238001` → Guardar → mensaje "RUC no es un RUC ecuatoriano válido".)**

> "Para demostrar que no depende de JavaScript, abro las herramientas del navegador, quito el atributo `pattern` del campo… y el servidor lo rechaza igual."

**(F12 → Elements → borra `pattern`/`required` del input → escribe un RUC inválido → sigue rechazando.)**

> "Con el RUC correcto, `1791234561001`, sí se guarda."

**(Guarda. Muestra el código de `EcuadorDocumento` en VS Code 5 segundos: "módulo 11".)**

## 6. Usuarios, roles y cédula (2:30 – 2:55)
> "Los usuarios tienen rol y, si son técnicos, una empresa que elijo de una lista. La cédula también se valida en el servidor con el módulo 10."

**(Usuarios → Nuevo → rol Técnico, empresa del dropdown, cédula `1710034066` → rechazo. Corrige a `1710034065` → guarda.)**

## 7. Cierre (2:55 – 3:00)
> "Con esto el core ya tiene los datos maestros. El código y el README están en mi GitHub, y la app está desplegada. Gracias."

---

## Checklist de la rúbrica
- [ ] ≥ 1 validación back-end de dato sensible → sección 5 (RUC) y 6 (cédula)
- [ ] FK con dropdown, no input simple → sección 4 (provincia → ciudad), 6 (empresa)
- [ ] Código en Git con README → mostrar el repositorio
- [ ] Deploy → grabar con la URL pública
