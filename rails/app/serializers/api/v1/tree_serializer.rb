class Api::V1::TreeSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :favourite, :patient_id, :number_of_levels, :number_of_pages, :root_page_id, :pages

  def pages
    ActiveModelSerializers::SerializableResource.new(object.root_page.subtree.includes(cards:[:card_tags], page_layouts:[card:[:card_tags]]), each_serializer: Api::V1::PageSerializer)
  end

  def number_of_levels
    return object.root_page.subtree.maximum(:ancestry_depth) + 1
  end

  def number_of_pages
    object.root_page.subtree.count
  end

  def favourite
    object.is_favourite
  end
end
