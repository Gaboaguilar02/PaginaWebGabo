module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[ edit update destroy ]
    before_action :cargar_empresas, only: %i[ new create edit update ]

    def index
      @role = params[:role] if User::ROLES.include?(params[:role])
      @users = User.includes(:company).order(:username)
      @users = @users.where(role: @role) if @role
    end

    def new
      @user = User.new(role: "cliente")
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_users_path, notice: "Usuario creado correctamente"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if quita_su_propio_acceso?
        @user.errors.add(:base, "No puedes quitarte el rol de administrador ni desactivar tu propia cuenta")
        render :edit, status: :unprocessable_entity
      elsif @user.update(user_params)
        redirect_to admin_users_path, notice: "Usuario actualizado correctamente"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "No puedes eliminar tu propia cuenta", status: :see_other
      elsif @user.destroy
        redirect_to admin_users_path, notice: "Usuario eliminado", status: :see_other
      else
        redirect_to admin_users_path, alert: @user.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def cargar_empresas
      @companies = Company.order(:nombre)
    end

    def quita_su_propio_acceso?
      return false unless @user == current_user

      datos = params.require(:user)
      (datos[:role].present? && datos[:role] != "admin") || datos[:activo] == "0"
    end

    def user_params
      permitidos = params.require(:user).permit(:username, :nombre_completo, :cedula, :role, :company_id, :activo,
                                                :password, :password_confirmation)
      # Al editar, dejar la contraseña en blanco significa "no cambiarla".
      if permitidos[:password].blank?
        permitidos.delete(:password)
        permitidos.delete(:password_confirmation)
      end
      permitidos
    end
  end
end
