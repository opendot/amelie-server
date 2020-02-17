class Text < Content
  before_save :truncate_content_to_string_length
  before_save :set_default_thumbnail

  protected

  def set_default_thumbnail
    self.content_thumbnail = nil
  end
end
