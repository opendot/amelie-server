class CreatePages < ActiveRecord::Migration[5.1]
  def change
    create_table :pages, id: :string do |t|
      t.string :name
      t.string :session_event_id, index: true
      t.string :patient_id, index: true
      t.string :type

      t.timestamps
    end
  end
end
