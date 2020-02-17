module TreeCreation
  # Contains helper methods to create a new Tree

  # Given the params received, extract the well-formed params 
  # to create Pages, Cards ans PageLayouts
  def extract_pages_cards_params parameters, tree
    card_ids = []
    page_layouts = []
    pages = []
    # Don't clone cards any more.
    # cards_source_ids = {}
    # cards_modified_ids = []
    # Get pages and cards. Pages are definitive, cards need to be copied.
    parameters[:pages].each do |page|
      if page[:level] == 0
        tree[:root_page_id] = page[:id]
      end
      page[:cards].each do |card|
        # Don't clone cards any more.
        # new_card_id = SecureRandom.uuid()
        # cards_source_ids[new_card_id] = card[:id]
        # cards_modified_ids.push(new_card_id)
        card_ids.push(card[:id])
        layout = create_page_layout_hash(page, card)
        
        page_layouts.push(layout)
      end
      
      new_page = create_page_hash(page, "ArchivedCardPage", parameters[:patient_id])
      pages.push(new_page)
    end

    if tree[:root_page_id].nil?
      @errors = [I18n.t("errors.trees.missing_root_page")]
      raise ActiveRecord::Rollback, @errors
    end

    return [pages, card_ids, page_layouts]

  end

  def create_page_layout_hash page, card
    layout = {}
    layout[:page_id] = page[:id]
    # layout[:card_id] = new_card_id
    layout[:card_id] = card[:id]
    layout[:x_pos] = card[:x_pos]
    layout[:y_pos] = card[:y_pos]
    layout[:scale] = card[:scale]
    layout[:next_page_id] = card[:next_page_id]
    layout[:selectable] = card[:selectable]
    layout[:hidden_link] = card[:hidden_link].nil??false:card[:hidden_link]
    return layout
  end

  def create_page_hash page, type, patient_id = nil
    new_page = {}
    new_page[:type] = type
    new_page[:name] = page[:name]
    new_page[:patient_id] = patient_id
    new_page[:id] = page[:id]
    new_page[:background_color] = page[:background_color]
    return new_page
  end


  # Change the ids of all pages and updates the refrences
  def change_page_ids tree, pages, card_ids, page_layouts
    pages_ids_mapping = {}
    pages_ids = []
    pages.each do |page|
      new_page_id = SecureRandom.uuid()
      pages_ids.push(new_page_id)
      pages_ids_mapping[page[:id]] = new_page_id
      page[:id] = new_page_id
    end

    # Don't clone cards any more.
    # Now I know which cards have to be copied. Let's get them.
    # original_cards = Card.where(id: card_ids)
    # content_ids = []
    # cards = []
    # original_cards.each do |card|
    #   content_ids.push(card[:content_id])
    # end

    # Get all contents
    # original_contents = Content.where(id: content_ids)
    # contents = []
    # card_to_content_mapping = {}

    # Clone the contents
    # cards_modified_ids.each do |id|
    #   original_card_id = cards_source_ids[id]
    #   original_content = original_contents.find{|c| c[:card_id] == original_card_id}
    #   cloned_content = original_content.get_an_unsaved_clone
    #   cloned_content[:card_id] = id
    #   new_content_id = SecureRandom.uuid()
    #   cloned_content[:id] = new_content_id
    #   card_to_content_mapping[id] = new_content_id
    #   contents.push(cloned_content)
    # end

    # Retrieve the required original cards from the previously created array and clone the,.
    # Take care to reassign them the correct content ids.
    # cards_modified_ids.each do |id|
    #   card = original_cards.find{|c| c[:id] == cards_source_ids[id]}
    #   cloned_card = card.get_an_unsaved_clone
    #   cloned_card[:patient_id] = parameters[:patient_id]
    #   linked_card = card_to_content_mapping[id]
    #   cloned_card[:content_id] = linked_card
    #   cloned_card[:id] = id
    #   cards.push(cloned_card)
    # end

    # Pages has changed ids. Update cards' references and create the tree structure.
    page_layouts.each do |layout|
      layout[:page_id] = pages_ids_mapping[layout[:page_id]]
      unless layout[:next_page_id].blank?
        layout[:next_page_id] = pages_ids_mapping[layout[:next_page_id]]
        child = pages.find{|p| p[:id] == layout[:next_page_id]}
        parent = pages.find{|p| p[:id] == layout[:page_id]}
        child[:parent_id] = parent[:id]
      end
    end

    # The root page changed id. Update tree's reference
    tree[:root_page_id] = pages_ids_mapping[tree[:root_page_id]]

    # Don't clone cards any more.
    # Now I can create contents.
    # Content.create!(contents)

    # Now I can create cards. They reference contents.
    # Card.create!(cards)
  end

  # reorder pages to be sure that parents are created before their childrens
  def reorder_pages pages
    reordered_pages = []
    to_be_removed = []
    # Add root page(s)
    pages.each do |p|
      if p[:parent_id].blank?
        reordered_pages.push(p) 
        to_be_removed.push(p)
      end
    end

    pages = pages.reject {|p| to_be_removed.include? p}

    iterations = 0
    while pages.count > 0 && iterations < 500
      to_be_removed = []
      pages.each do |p|
        reordered_pages.each do |r|
          if r[:id] == p[:parent_id]
            to_be_removed.push(p)
          end
        end
      end
      reordered_pages.push(*to_be_removed)
      pages = pages.reject {|p| to_be_removed.include? p}
      pages = [] if pages.nil?
      iterations += 1
    end

    return reordered_pages
  end

  # Create the presentation page if exist
  def create_presentation_page tree, presentation_page_params
    return if presentation_page_params.nil?

    # Create hash
    page_layouts = []
    presentation_page_params[:cards].each do |card|
      # Clone cards, this allows to have only archived_cards inside the presentation page
      cloned_card = Card.find(card[:id]).get_a_clone()
      dup_card = card.deep_dup
      dup_card[:id] = cloned_card.id 
      layout = create_page_layout_hash(presentation_page_params, dup_card)
      
      page_layouts.push(layout)
    end
    new_presentation_page = create_page_hash(presentation_page_params, "PresentationPage")

    # Create the presentation page from hash
    presentation_page = PresentationPage.create!(new_presentation_page)
    PageLayout.create!(page_layouts)

    # Connect to tree
    tree.presentation_page = presentation_page
  end
  
end