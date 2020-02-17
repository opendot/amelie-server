module ExtraPage
  # Methods for pages that are outside the normal flow of the tree

  def set_card_not_selectable page_layout
    page_layout.update!(selectable: false)
  end

  def set_cards_not_selectable
    self.page_layouts.update_all(selectable: false, updated_at: DateTime.now)
  end

  def get_a_clone_with_next_page(next_page_id)
    clone = self.get_a_clone
    clone.page_layouts.update_all(next_page_id: next_page_id, updated_at: DateTime.now)
    return clone
  end

end