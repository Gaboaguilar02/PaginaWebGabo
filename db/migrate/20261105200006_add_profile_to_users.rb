class AddProfileToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :nombre_completo, :string
    add_column :users, :cedula, :string
    add_column :users, :role, :string, null: false, default: "cliente"
    add_column :users, :activo, :boolean, null: false, default: true
    add_reference :users, :company, null: true, foreign_key: true

    add_index :users, :cedula, unique: true

    # El usuario "admin" que ya existía antes de los roles pasa a ser administrador.
    reversible do |direction|
      direction.up { execute "UPDATE users SET role = 'admin' WHERE username = 'admin'" }
    end
  end
end
