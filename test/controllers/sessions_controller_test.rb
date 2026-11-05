require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "muestra el formulario de login" do
    get login_url
    assert_response :success
  end

  test "un administrador entra al panel de administración" do
    login_as users(:admin)
    assert_redirected_to admin_root_url
  end

  test "un cliente entra a la sección de productos" do
    login_as users(:cliente)
    assert_redirected_to products_url
  end

  test "rechaza una contraseña incorrecta" do
    login_as users(:admin), password: "incorrecta"
    assert_response :unprocessable_entity
    assert_match "Usuario o contraseña incorrectos", response.body
  end

  test "rechaza un usuario inexistente" do
    post login_path, params: { username: "fantasma", password: "password123" }
    assert_response :unprocessable_entity
  end

  test "un usuario inactivo no puede iniciar sesión" do
    login_as users(:inactivo)
    assert_response :unprocessable_entity
  end

  test "el nombre de usuario no distingue mayúsculas" do
    post login_path, params: { username: "ADMIN", password: "password123" }
    assert_redirected_to admin_root_url
  end

  test "cerrar sesión bloquea de nuevo las URLs protegidas" do
    login_as users(:admin)
    delete logout_path
    assert_redirected_to login_url

    get admin_companies_url
    assert_redirected_to login_url
  end

  test "un usuario desactivado pierde el acceso aunque tenga sesión abierta" do
    login_as users(:cliente)
    users(:cliente).update_columns(activo: false)

    get products_url
    assert_redirected_to login_url
  end
end
