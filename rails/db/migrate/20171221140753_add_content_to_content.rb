class AddContentToContent < ActiveRecord::Migration[5.1]
  def change
    add_column :contents, :content, :string
    add_column :contents, :content_thumbnail, :string
  end
end
