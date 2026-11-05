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
