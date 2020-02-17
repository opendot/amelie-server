class CreateSessionEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :session_events, id: :string do |t|
      t.datetime :timestamp, limit: 5
      t.string :training_session_id, index: true
      t.string :page_id, index: true
      t.string :tracker_calibration_parameter_id, index: {name: 'index_tracker_calibration_parameter_id_on_session_events'}
      t.string :card_id, index: true
      t.string :next_page_id, index: true
      t.string :type

      t.timestamps
    end
  end
end
