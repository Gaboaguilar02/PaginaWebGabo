# Despliegue en Render (Docker)

El proyecto ya trae un `Dockerfile` listo para producción y un `render.yaml`. Con SQLite, el plan gratuito de Render guarda los datos en un disco **efímero**: cada reinicio o redeploy recrea la base y vuelve a cargar los *seeds* (provincias, ciudades, catálogo, admin y datos demo). Para la entrega basta; para datos permanentes usa un disco persistente de pago o PostgreSQL.

> Verifica en render.com las condiciones vigentes del plan gratuito (límites, suspensión por inactividad: la primera visita después de un rato puede tardar ~1 minuto).

## Opción A: con el Blueprint (`render.yaml`)
1. Sube el código a GitHub (rama `main`).
2. En Render: **New → Blueprint** → elige el repositorio `PaginaWebGabo`.
3. Render lee `render.yaml`. Cuando pida los valores `sync: false`, escribe:
   - `ADMIN_PASSWORD`: una contraseña **fuerte** para `admin` (no uses `admin123` en público).
   - `DEMO_PASSWORD`: contraseña de los usuarios demo (o agrega `SEED_DEMO=false` para no crearlos).
4. **Apply** y espera el build. Al terminar tendrás una URL `https://paginawebgabo-xxxx.onrender.com`.

## Opción B: manual
1. **New → Web Service** → conecta el repositorio → **Runtime: Docker**.
2. **Docker Command:** `./bin/rails server`
3. **Health Check Path:** `/up`
4. Variables de entorno:

| Variable | Valor |
|----------|-------|
| `RAILS_ENV` | `production` |
| `BINDING` | `0.0.0.0` |
| `SECRET_KEY_BASE` | salida de `bin/rails secret` |
| `RAILS_LOG_TO_STDOUT` | `true` |
| `RAILS_SERVE_STATIC_FILES` | `true` |
| `ADMIN_PASSWORD` | contraseña fuerte |
| `DEMO_PASSWORD` | contraseña de los usuarios demo |

## Después del deploy
1. Abre la URL y entra con `admin` y tu `ADMIN_PASSWORD`.
2. Pega la URL en el README (sección **Demo**) y haz commit.
3. Para el video, graba **la URL desplegada**, no `localhost`.

## Problemas frecuentes
- **El build falla en `assets:precompile`:** revisa el log; el Dockerfile ya usa `SECRET_KEY_BASE_DUMMY=1` para esa etapa.
- **"Application error" al abrir:** revisa los *Logs* de Render. Si dice `SECRET_KEY_BASE`, falta esa variable.
- **Redirige en bucle a HTTPS:** en `config/environments/production.rb` deben estar activas `assume_ssl` y `force_ssl` (ya lo están).
- **Se perdieron los datos que creé:** es el disco efímero; vuelve a crearlos o usa disco persistente.
