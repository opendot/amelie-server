class AddPresentationPageToTrees < ActiveRecord::Migration[5.1]
  def change
    add_column :trees, :presentation_page_id, :string
  end
end
