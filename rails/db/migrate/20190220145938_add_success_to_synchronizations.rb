class AddSuccessToSynchronizations < ActiveRecord::Migration[5.1]
  def change
    add_column :synchronizations, :success, :boolean
    add_column :synchronizations, :ongoing, :boolean
    add_column :synchronizations, :started_at, :datetime
    add_column :synchronizations, :completed_at, :datetime
  end
end
