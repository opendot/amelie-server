class AddStrongFeedbackPageIdToTrees < ActiveRecord::Migration[5.1]
  def change
    add_column :trees, :strong_feedback_page_id, :string
  end
end
