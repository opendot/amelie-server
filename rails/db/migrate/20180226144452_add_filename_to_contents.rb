class AddFilenameToContents < ActiveRecord::Migration[5.1]
  def change
    add_column :contents, :filename, :string
  end
end
