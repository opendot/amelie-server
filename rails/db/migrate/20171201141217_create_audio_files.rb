class CreateAudioFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :audio_files, id: :string do |t|
      t.string :name
      t.string :training_session_id, index: true

      t.timestamps
    end
  end
end
