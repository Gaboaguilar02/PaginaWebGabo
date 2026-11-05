class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :require_login
  helper_method :current_user, :logged_in?

  private

  # Un usuario desactivado pierde el acceso de inmediato, aunque tenga sesión abierta.
  def current_user
    return @current_user if defined?(@current_user)

    @current_user = session[:user_id] ? User.activos.find_by(id: session[:user_id]) : nil
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    redirect_to login_path, alert: "Debes iniciar sesión" unless logged_in?
  end

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
