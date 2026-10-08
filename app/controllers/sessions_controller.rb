class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new
    redirect_to products_path if logged_in?
  end

  def create
    user = User.find_by(username: params[:username])
    if user&.authenticate(params[:password])
      reset_session
      session[:user_id] = user.id
      redirect_to products_path, notice: "Bienvenido, #{user.username}"
    else
      flash.now[:alert] = "Usuario o contraseña incorrectos"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Sesión cerrada"
  end
end