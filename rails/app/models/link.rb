class Link < Content
  before_save :truncate_content_to_string_length

  mount_base64_uploader :content_thumbnail, LinkContentUploader
end
