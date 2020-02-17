class AddBackgroundColorToPages < ActiveRecord::Migration[5.1]
  def change
    add_column :pages, :background_color, :string
  end
end
