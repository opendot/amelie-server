class CreateTags < ActiveRecord::Migration[5.1]
  def change
    create_table :tags, id: :string do |t|
      t.string :tag
      t.string :type
      t.index :tag

      t.timestamps
    end
  end
end
