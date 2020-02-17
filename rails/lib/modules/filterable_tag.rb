module FilterableTag
  # Filter a list of tags by tag and returns the results
  # Will return a list of tags starting with 'query' followed by a list of tags
  # containing 'query'
  def filter_by_query (tags, query)
    if query.nil? || query == ""
      return tags
    end
    results_one = tags.where("tag LIKE :query", query: "#{query}%")
    results_two = tags.where("tag LIKE :query", query: "%#{query}%").where.not("tag LIKE :query", query: "#{query}%")
    return results_one + results_two
  end
end