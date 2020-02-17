class Api::V1::ContentSerializer < ActiveModel::Serializer
  attributes :type, :content, :content_thumbnail

  def content
    if object.is_a?(Pictogram) || object.is_a?(Medium)
      return object.content.url
    else
      return object.content
    end
  end

  def content_thumbnail
    if object.is_a?(Text)
      return nil
    end
    if object.is_a?(Pictogram) || object.is_a?(Video)
      if object.content_thumbnail.url.nil?
        return object.content.thumb.url
      else
        return object.content_thumbnail.url
      end
    end
    if object.is_a?(Medium)
      return object.content_thumbnail.url
    end
    return object.content_thumbnail
  end
end
