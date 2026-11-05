require "test_helper"

class LocationTest < ActiveSupport::TestCase
  test "no se puede eliminar una provincia que tiene ciudades" do
    assert_no_difference("Province.count") { assert_not provinces(:pichincha).destroy }
    assert provinces(:pichincha).errors[:base].any?
  end

  test "no se puede eliminar una ciudad que tiene empresas" do
    assert_no_difference("City.count") { assert_not cities(:quito).destroy }
  end

  test "una ciudad pertenece a una provincia y no puede repetirse dentro de ella" do
    assert_not City.new(nombre: "Quito").valid?
    assert_not City.new(province: provinces(:pichincha), nombre: "quito").valid?
    assert City.new(province: provinces(:guayas), nombre: "Quito").valid?
  end

  test "el nombre de la provincia es único sin importar mayúsculas" do
    assert_not Province.new(nombre: "PICHINCHA").valid?
  end

  test "no se puede eliminar un electrodoméstico que usa una empresa" do
    assert_not appliance_types(:lavadora).destroy
    assert appliance_types(:descontinuado).destroy
  end
end
