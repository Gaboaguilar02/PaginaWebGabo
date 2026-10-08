# README

# Página Web Gabo: CRUD + Login con MVC

![Estado](https://img.shields.io/badge/estado-terminado-green)
![Ruby](https://img.shields.io/badge/Ruby-3.4.1-CC342D?logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Rails-8.1-D30001?logo=rubyonrails&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-3-003B57?logo=sqlite&logoColor=white)

> Aplicación web con patrón MVC que implementa un CRUD de productos protegido por un sistema de autenticación.

## Índice
- [Descripción](#descripción)
- [Funcionalidades](#funcionalidades)
- [Demo](#demo)
- [Arquitectura MVC](#arquitectura-mvc)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Tecnologías](#tecnologías)
- [Instalación](#instalación)
- [Acceso](#acceso)
- [Rutas](#rutas)
- [Seguridad](#seguridad)
- [Autor](#autor)

## Descripción
Proyecto académico desarrollado con **Ruby on Rails** que aplica el patrón Modelo-Vista-Controlador (MVC). Incluye un sistema de login con sesiones y un CRUD de productos al que solo pueden acceder usuarios autenticados. Cualquier URL protegida redirige a `/login` si no hay sesión iniciada.

## Funcionalidades
- ✅ Inicio y cierre de sesión
- ✅ Todas las URLs protegidas: sin sesión se redirige a `/login`
- ✅ Crear, listar, editar y eliminar productos (CRUD completo)
- ✅ Contraseñas encriptadas con bcrypt (nunca en texto plano)
- ✅ Mensajes de aviso y de error en el login

## Demo
🎥 [Ver video de demostración](PEGA_AQUI_EL_LINK_DE_LOOM_O_YOUTUBE)

El video muestra:
1. El funcionamiento del login
2. Que no se puede acceder a la sección protegida sin iniciar sesión
3. La contraseña almacenada con encriptación en la base de datos

## Arquitectura MVC
| Capa | Ubicación | Función |
|------|-----------|---------|
| Modelo | `app/models/user.rb`, `app/models/product.rb` | Datos y validaciones |
| Vista | `app/views/` | Pantallas en ERB |
| Controlador | `app/controllers/sessions_controller.rb`, `app/controllers/products_controller.rb` | Lógica de login y CRUD |
| Rutas | `config/routes.rb` | Conecta URLs con controladores |

## Estructura del proyecto
```
PaginaWebGabo/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb   # protege toda la app
│   │   ├── sessions_controller.rb      # login / logout
│   │   └── products_controller.rb      # CRUD
│   ├── models/
│   │   ├── user.rb
│   │   └── product.rb
│   └── views/
│       ├── layouts/application.html.erb
│       ├── sessions/new.html.erb
│       └── products/
├── config/routes.rb
├── db/
│   ├── migrate/
│   └── seeds.rb                        # crea el usuario admin
└── README.md
```

## Tecnologías
- Ruby 3.4.1
- Ruby on Rails 8.1
- SQLite
- bcrypt (`has_secure_password`)

## Instalación
**Requisitos:** Ruby 3.4 o superior y Rails 8. En Windows se recomienda usar WSL2 con Ubuntu.

```bash
git clone https://github.com/Gaboaguilar02/PaginaWebGabo.git
cd PaginaWebGabo
bundle install
rails db:setup
rails server
```

`rails db:setup` crea la base de datos, ejecuta las migraciones y genera el usuario administrador.

Abre http://127.0.0.1:3000

## Acceso
| Usuario | Contraseña |
|---------|------------|
| admin   | admin123   |

## Rutas
| Método | Ruta | Descripción | Requiere sesión |
|--------|------|-------------|:---------------:|
| GET | `/login` | Formulario de login | No |
| POST | `/login` | Iniciar sesión | No |
| DELETE | `/logout` | Cerrar sesión | Sí |
| GET | `/products` | Listar productos | Sí |
| GET | `/products/new` | Formulario de creación | Sí |
| POST | `/products` | Crear producto | Sí |
| GET | `/products/:id/edit` | Formulario de edición | Sí |
| PATCH/PUT | `/products/:id` | Actualizar producto | Sí |
| DELETE | `/products/:id` | Eliminar producto | Sí |

## Seguridad
- Contraseñas guardadas como hash **bcrypt** con sal, no en texto plano
- `before_action :require_login` en `ApplicationController`, que protege todos los controladores por defecto
- `reset_session` al iniciar y cerrar sesión para evitar *session fixation*
- Protección CSRF y *strong parameters* incluidos en Rails

## Autor
Gabriel Mauricio Aguilar Polit: [GitHub](https://github.com/Gaboaguilar02)