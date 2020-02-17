class AddDirectionToSynchronizations < ActiveRecord::Migration[5.1]
  def change
    add_column :synchronizations, :direction, :string
  end
end
