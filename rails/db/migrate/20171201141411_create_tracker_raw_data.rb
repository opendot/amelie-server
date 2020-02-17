class CreateTrackerRawData < ActiveRecord::Migration[5.1]
  def change
    create_table :tracker_raw_data, id: :string do |t|
      t.datetime :timestamp, limit: 5
      t.float :x_position
      t.float :y_position
      t.string :training_session_id, index: true

      t.timestamps
    end
  end
end
