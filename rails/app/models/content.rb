class Content < ApplicationRecord
  include ActionView::Helpers::TextHelper
  include Synchronizable
  # The content shown by a card, it's a wrapper for an image, video, audio or anything else
  # id: string                  unique identifier, it must be unique even among different computers
  # type: string                Single Table Inheritance
  # content: object             object related to carrierwave
  # content_thumbnail: object   object related to carrierwave
  # filename: string            name of the file, it's the id of the original content created when uploading the file
  # size: integer               size of the file in Byte
  # duration: float             duration of the file in seconds

  TYPES = %w(PersonalImage GenericImage DrawingImage IconImage Medium Text Link Video).freeze
  ALL_TYPES = [self.name].concat(TYPES).freeze

  has_many :cards

  validates :type, inclusion: { in: TYPES, message: "%{value} #{I18n.t :error_content_type}" }
  validates :type, presence: true

  def as_json(options={})
    super(options.merge({:methods => :type}))
  end

  default_scope { order(:created_at) }

  public

  # Returns a deep clone of the current object
  def get_a_clone
    new_content = get_an_unsaved_clone
    new_content[:id] = SecureRandom.uuid()
    new_content = Content.create(new_content)
    unless new_content.persisted?
      raise ActiveRecord::Rollback, "Can't save the cloned content: #{new_content.errors.full_messages}"
    end
    return new_content
  end

  # Returns an unsaved clone of the current content. Id will not be changed.
  def get_an_unsaved_clone
    new_content = {}
    new_content[:filename] = self.filename
    new_content[:type] = self.type
    if self.is_a?(Pictogram) || self.is_a?(Medium)
      new_content[:remote_content_url] = self.content_url
      new_content[:remote_content_thumbnail_url] = self.content_thumbnail_url
      # new_content[:content] = self.content.deep_dup
      # new_content[:content_thumbnail] = self.content_thumbnail.deep_dup
    else
      new_content[:content] = self.content
      new_content[:content_thumbnail] = self.content_thumbnail
    end
    new_content[:id] = self.id
    return new_content
  end

  protected

  def truncate_content_to_string_length
    self.content = truncate(self.content, :length => 255)
  end

end
