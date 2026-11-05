require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  def empresa_valida(overrides = {})
    Company.new({ nombre: "Nueva Empresa", ruc: "1791234561001", city: cities(:quito), status: "pendiente" }.merge(overrides))
  end

  test "los fixtures son válidos" do
    Company.all.each { |empresa| assert empresa.valid?, "#{empresa.nombre}: #{empresa.errors.full_messages.to_sentence}" }
  end

  test "rechaza un RUC inválido en el servidor" do
    empresa = empresa_valida(ruc: "1790001238001")
    assert_not empresa.valid?
    assert_includes empresa.errors[:ruc], "no es un RUC ecuatoriano válido"
  end

  test "rechaza un RUC con longitud o caracteres incorrectos" do
    [ "123", "17900012370011", "17900012AB001", "" ].each do |ruc|
      assert_not empresa_valida(ruc: ruc).valid?, "#{ruc.inspect} no debería ser válido"
    end
  end

  test "rechaza un RUC repetido" do
    assert_not empresa_valida(ruc: companies(:tecnifrio).ruc).valid?
  end

  test "la ciudad es obligatoria y debe existir" do
    assert_not empresa_valida(city: nil).valid?
    assert_not empresa_valida(city: nil, city_id: 999_999).valid?
  end

  test "la provincia se obtiene a través de la ciudad" do
    assert_equal provinces(:pichincha), companies(:tecnifrio).province
  end

  test "el estado debe ser uno de los permitidos" do
    assert_not empresa_valida(status: "inventado").valid?
  end

  test "el teléfono solo admite caracteres de teléfono" do
    assert_not empresa_valida(telefono: "abc-defg").valid?
    assert empresa_valida(telefono: "+593 2 234-5678").valid?
  end

  test "no se puede activar una empresa sin electrodomésticos" do
    empresa = companies(:hogarfix)
    empresa.status = "activa"
    assert_not empresa.valid?
    assert_match(/al menos un tipo de electrodoméstico/, empresa.errors.full_messages.to_sentence)

    empresa.appliance_types = [ appliance_types(:lavadora) ]
    assert empresa.valid?
  end

  test "no se puede eliminar una empresa que tiene usuarios" do
    assert_no_difference("Company.count") { assert_not companies(:tecnifrio).destroy }
    assert companies(:tecnifrio).errors[:base].any?
  end

  test "al eliminar una empresa se eliminan sus asignaciones de electrodomésticos" do
    empresa = empresa_valida(appliance_types: [ appliance_types(:lavadora), appliance_types(:secadora) ])
    empresa.save!

    assert_difference("CompanyApplianceType.count", -2) do
      assert_difference("Company.count", -1) { empresa.destroy }
    end
  end
end
