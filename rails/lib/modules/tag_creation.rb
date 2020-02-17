module TagCreation
  # Contains helper methods to create tags when creating another object

  def create_tag_objects(tags, tag_type)
    my_tags = []
    tags.each do |tag|
      t = Tag.create(id: SecureRandom.uuid(), type: tag_type, tag: tag)
      my_tags.push(t)
    end
    return my_tags
  end

end