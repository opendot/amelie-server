class CreateTrees < ActiveRecord::Migration[5.1]
  def change
    create_table :trees, id: :string do |t|
      t.string :name
      t.boolean :favourite, null: false, default: false
      t.string :root_page_id
      t.string :patient_id, index: true

      t.timestamps
    end
  end
end
