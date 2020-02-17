class Medium < Content
  mount_base64_uploader :content, MediaContentUploader
  mount_base64_uploader :content_thumbnail, ThumbnailContentUploader

  scope :longer_than,  ->  (seconds){ where("duration > ?", seconds) } 
end
