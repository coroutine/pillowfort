class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :email
      t.string :password_digest
      t.string :auth_token
      t.datetime :auth_token_expires_at

      t.timestamps null: false
    end
  end
end
