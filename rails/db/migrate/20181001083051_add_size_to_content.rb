class AddSizeToContent < ActiveRecord::Migration[5.1]
  def change
    add_column :contents, :size, :integer
    add_column :contents, :duration, :float
  end
end
