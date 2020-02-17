class Api::V1::AudioFileSerializer < ActiveModel::Serializer
  attributes :id, :name, :audio_file_url

  def audio_file_url
    if object.audio_file.nil?
      return nil
    end
    object.audio_file.url
  end
end
