require "test_helper"

class UserTest < ActiveSupport::TestCase
  def usuario_valido(overrides = {})
    User.new({ username: "nuevo", nombre_completo: "Nuevo Usuario", cedula: "1710034065", role: "cliente",
               password: "secreto123", password_confirmation: "secreto123" }.merge(overrides))
  end

  test "los fixtures son válidos" do
    User.all.each { |usuario| assert usuario.valid?, "#{usuario.username}: #{usuario.errors.full_messages.to_sentence}" }
  end

  test "guarda la contraseña encriptada y no en texto plano" do
    usuario = usuario_valido
    assert usuario.save
    assert_not_equal "secreto123", usuario.password_digest
    assert usuario.password_digest.start_with?("$2")
    assert usuario.authenticate("secreto123")
  end

  test "rechaza una cédula inválida en el servidor" do
    usuario = usuario_valido(cedula: "1710034066")
    assert_not usuario.valid?
    assert_includes usuario.errors[:cedula], "no es una cédula ecuatoriana válida"
  end

  test "rechaza una cédula con letras o longitud incorrecta" do
    [ "abc", "12345", "17100340651", "17100340AB" ].each do |cedula|
      assert_not usuario_valido(cedula: cedula).valid?, "#{cedula} no debería ser válida"
    end
  end

  test "rechaza una cédula repetida" do
    usuario = usuario_valido(cedula: users(:cliente).cedula)
    assert_not usuario.valid?
    assert usuario.errors[:cedula].any?
  end

  test "la cédula es obligatoria" do
    assert_not usuario_valido(cedula: "").valid?
  end

  test "el nombre de usuario se normaliza a minúsculas y es único sin importar mayúsculas" do
    usuario = usuario_valido(username: "  CLIENTE1 ")
    assert_not usuario.valid?
    assert_equal "cliente1", usuario.username
    assert usuario.errors[:username].any?
  end

  test "un técnico debe pertenecer a una empresa" do
    usuario = usuario_valido(role: "tecnico")
    assert_not usuario.valid?
    assert usuario.errors[:company_id].any?

    usuario.company = companies(:tecnifrio)
    assert usuario.valid?
  end

  test "un cliente o administrador no puede tener empresa" do
    assert_not usuario_valido(role: "cliente", company: companies(:tecnifrio)).valid?
    assert_not usuario_valido(role: "admin", company: companies(:tecnifrio)).valid?
  end

  test "rechaza un rol inexistente" do
    assert_not usuario_valido(role: "superusuario").valid?
  end

  test "la contraseña debe tener al menos 6 caracteres" do
    assert_not usuario_valido(password: "123", password_confirmation: "123").valid?
  end

  test "los métodos de rol funcionan" do
    assert users(:admin).admin?
    assert users(:tecnico).tecnico?
    assert_not users(:cliente).admin?
  end
end
