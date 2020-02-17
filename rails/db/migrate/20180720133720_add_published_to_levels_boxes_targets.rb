class AddPublishedToLevelsBoxesTargets < ActiveRecord::Migration[5.1]
  def change
    add_column :levels, :published, :boolean, default: true
    add_column :boxes, :published, :boolean, default: true
    add_column :targets, :published, :boolean, default: true
  end
end
