class CreateContents < ActiveRecord::Migration[5.1]
  def change
    create_table :contents, id: :string do |t|
      t.string :card_id, index: true
      t.string :type

      t.timestamps
    end
  end
end
