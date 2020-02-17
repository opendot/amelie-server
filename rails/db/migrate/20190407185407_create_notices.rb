class CreateNotices < ActiveRecord::Migration[5.1]
  def change
    create_table :notices,id: :string do |t|
      t.text :message
      t.boolean :read, default: false
      t.references :user, foreign_key: true, type: :string

      t.timestamps
    end
  end
end
