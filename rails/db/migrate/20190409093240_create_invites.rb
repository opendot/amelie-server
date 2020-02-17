class CreateInvites < ActiveRecord::Migration[5.1]
  def change
    create_table :invites,id: :string do |t|
      t.string :mail
      t.references :user, foreign_key: true, type: :string

      t.timestamps
    end
  end
end
