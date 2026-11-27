ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module LoginHelper
  PASSWORD_DE_PRUEBA = "password123".freeze

  # Inicia sesión haciendo el POST real al login (igual que lo haría el navegador).
  def login_as(user, password: PASSWORD_DE_PRUEBA)
    post login_path, params: { username: user.username, password: password }
  end
end

class ActionDispatch::IntegrationTest
  include LoginHelper
end

# Ayudas para armar escenarios del ranking y los bonos.
module RankingHelper
  # Crea +cantidad+ casos resueltos de un técnico dentro del mes de +mes+ (un Date) con la calificación dada.
  def resolver_casos(tecnico, mes, cantidad, calificacion: 5)
    inicio = mes.beginning_of_month.in_time_zone
    cantidad.times do |i|
      resuelta = inicio + (i % 25).days + 9.hours
      RepairCase.create!(
        client: User.find_by!(username: "cliente1"), company: tecnico.company, appliance_type: ApplianceType.find_by!(nombre: "Lavadora"),
        city: City.find_by!(nombre: "Quito"), falla: "Caso resuelto de prueba número #{SecureRandom.hex(4)}", direccion: "Av. Test 123",
        status: "resuelta", technician: tecnico, created_at: resuelta - 1.day, resuelta_at: resuelta,
        calificacion: calificacion, feedback_at: resuelta
      )
    end
  end

  def crear_escalones(company)
    [ [ "Bronce", 5, 5 ], [ "Plata", 10, 10 ], [ "Oro", 15, 15 ] ].map do |nombre, casos, porcentaje|
      BonusTier.create!(company: company, nombre: nombre, casos_minimos: casos, porcentaje: porcentaje)
    end
  end

  def mes_anterior = Date.current.beginning_of_month - 1.month
  def mes_actual = Date.current.beginning_of_month
end

class ActiveSupport::TestCase
  include RankingHelper
end
