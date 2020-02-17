class CreatePatients < ActiveRecord::Migration[5.1]
  def change
    create_table :patients, id: :string do |t|
      t.string :name, null: false
      t.string :surname, null: false
      t.date :birthdate, null: false
      t.timestamps
    end
  end
end
