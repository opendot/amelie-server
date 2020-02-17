class Video < Medium
  mount_base64_uploader :content, VideoContentUploader
end
