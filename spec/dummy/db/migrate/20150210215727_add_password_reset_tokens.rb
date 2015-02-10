class AddPasswordResetTokens < ActiveRecord::Migration
  def change
    change_table :accounts do |t|
      t.string :password_reset_token
      t.datetime :password_reset_token_expires_at
    end
  end
end
