require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:admin)
  end

  def datos_validos(overrides = {})
    { username: "tecnico2", nombre_completo: "Luis Paz", cedula: "1710034065", role: "tecnico",
      company_id: companies(:tecnifrio).id, activo: "1", password: "secreto123", password_confirmation: "secreto123" }.merge(overrides)
  end

  test "crea un técnico asignado a una empresa elegida del dropdown" do
    assert_difference("User.count", 1) { post admin_users_path, params: { user: datos_validos } }
    assert_redirected_to admin_users_path
    assert_equal companies(:tecnifrio), User.find_by(username: "tecnico2").company
  end

  test "la contraseña se guarda encriptada" do
    post admin_users_path, params: { user: datos_validos }
    usuario = User.find_by(username: "tecnico2")
    assert_not_equal "secreto123", usuario.password_digest
    assert usuario.authenticate("secreto123")
  end

  test "el servidor rechaza una cédula inválida aunque el navegador la haya dejado pasar" do
    assert_no_difference("User.count") { post admin_users_path, params: { user: datos_validos(cedula: "1710034066") } }
    assert_response :unprocessable_entity
    assert_match "no es una cédula ecuatoriana válida", response.body
  end

  test "rechaza una cédula repetida" do
    assert_no_difference("User.count") { post admin_users_path, params: { user: datos_validos(cedula: users(:cliente).cedula) } }
    assert_response :unprocessable_entity
  end

  test "rechaza un técnico sin empresa" do
    assert_no_difference("User.count") { post admin_users_path, params: { user: datos_validos(company_id: "") } }
    assert_response :unprocessable_entity
  end

  test "rechaza un rol inventado" do
    assert_no_difference("User.count") { post admin_users_path, params: { user: datos_validos(role: "superadmin") } }
    assert_response :unprocessable_entity
  end

  test "rechaza una contraseña distinta a su confirmación" do
    assert_no_difference("User.count") { post admin_users_path, params: { user: datos_validos(password_confirmation: "otra") } }
    assert_response :unprocessable_entity
  end

  test "editar sin escribir contraseña conserva la actual" do
    cliente = users(:cliente)
    digest = cliente.password_digest

    patch admin_user_path(cliente), params: { user: { nombre_completo: "Ana María Torres", password: "", password_confirmation: "" } }
    assert_redirected_to admin_users_path
    assert_equal "Ana María Torres", cliente.reload.nombre_completo
    assert_equal digest, cliente.password_digest
  end

  test "editar con una contraseña nueva la cambia" do
    cliente = users(:cliente)
    patch admin_user_path(cliente), params: { user: { password: "nueva-clave", password_confirmation: "nueva-clave" } }
    assert cliente.reload.authenticate("nueva-clave")
  end

  test "un administrador no puede quitarse su propio rol ni desactivarse" do
    patch admin_user_path(users(:admin)), params: { user: { role: "cliente" } }
    assert_response :unprocessable_entity
    assert users(:admin).reload.admin?

    patch admin_user_path(users(:admin)), params: { user: { activo: "0" } }
    assert_response :unprocessable_entity
    assert users(:admin).reload.activo?
  end

  test "un administrador no puede eliminar su propia cuenta" do
    assert_no_difference("User.count") { delete admin_user_path(users(:admin)) }
    assert_redirected_to admin_users_path
  end

  test "elimina a otro usuario" do
    assert_difference("User.count", -1) { delete admin_user_path(users(:inactivo)) }
  end

  test "filtra el listado por rol" do
    get admin_users_path(role: "tecnico")
    assert_response :success
    assert_match "tecnico1", response.body
    assert_no_match(/cliente1/, response.body)
  end
end
