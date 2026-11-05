class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[ new create ]

  def new
    redirect_to inicio_para(current_user) if logged_in?
  end

  def create
    user = User.activos.find_by(username: params[:username].to_s.strip.downcase)
    if user&.authenticate(params[:password])
      reset_session
      session[:user_id] = user.id
      redirect_to inicio_para(user), notice: "Bienvenido, #{user.nombre_completo.presence || user.username}"
    else
      flash.now[:alert] = "Usuario o contraseña incorrectos"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Sesión cerrada"
  end

  private

  def inicio_para(user)
    user.admin? ? admin_root_path : products_path
  end
end
