class AddActivationTokenToAccount < ActiveRecord::Migration
  def change
    change_table :accounts do |t|
      t.datetime :activated_at
      t.string   :activation_token
      t.datetime :activation_token_expires_at
    end
  end
end
