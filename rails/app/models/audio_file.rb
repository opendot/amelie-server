# Audio files uploaded to the server
class AudioFile < ApplicationRecord
  include Synchronizable

  belongs_to :training_session

  validates :name, presence: true

  mount_base64_uploader :audio_file, AudioFileUploader
end
