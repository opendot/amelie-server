class Pictogram < Content

  mount_base64_uploader :content, ImageContentUploader
  mount_base64_uploader :content_thumbnail, ImageContentUploader

end
