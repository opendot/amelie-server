class AddAudioFileToAudioFile < ActiveRecord::Migration[5.1]
  def change
    add_column :audio_files, :audio_file, :string
  end
end
