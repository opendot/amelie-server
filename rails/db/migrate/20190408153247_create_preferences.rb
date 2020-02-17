class CreatePreferences < ActiveRecord::Migration[5.1]
  def change
    create_table :preferences do |t|
      t.integer :num_invites
      t.integer :user_expiration_days
      t.text :invite_text

      t.timestamps
    end
  end
end
