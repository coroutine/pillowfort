class AddAuthTokenTtlToAccount < ActiveRecord::Migration
  def change
    change_table :accounts do |t|
      t.integer :auth_token_ttl, null: false, default: 1.day
    end
  end
end
