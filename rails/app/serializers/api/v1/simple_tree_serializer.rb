class Api::V1::SimpleTreeSerializer < ActiveModel::Serializer
  attributes :id, :name, :favourite, :root_page_id, :number_of_pages, :number_of_levels, :type

  def number_of_levels
    object.root_page.subtree.maximum(:ancestry_depth) + 1
  end

  def number_of_pages
    object.root_page.subtree.count
  end

  def favourite
    object.is_favourite
  end
end
