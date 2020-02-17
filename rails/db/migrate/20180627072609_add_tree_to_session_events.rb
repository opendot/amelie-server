class AddTreeToSessionEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :session_events, :tree_id, :string
  end
end
