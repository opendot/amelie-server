class PagesPagetags < ActiveRecord::Migration[5.1]
  def change
    create_table :pages_page_tags, id: false do |t|
      t.string :page_id, index: true
      t.string :page_tag_id, index: true
    end
  end
end
