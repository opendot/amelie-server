class Tree < ApplicationRecord
  extend TreeCreation
  include Synchronizable
  
  belongs_to :root_page, class_name: 'Page', foreign_key: 'root_page_id', dependent: :destroy
  belongs_to :patient, optional: true
  belongs_to :presentation_page, optional: true, dependent: :destroy
  belongs_to :strong_feedback_page, class_name: 'FeedbackPage', optional: true

  validates :name, presence: true
  validates_with FavouriteTreeCountValidator

  default_scope { order(:created_at) }
  scope :add_max_depth, -> {joins("JOIN pages ON pages.ancestry LIKE CONCAT(trees.root_page_id, '%')").group(:id).select(:id, :root_page_id, :name).select("max(pages.ancestry_depth) AS max_depth")}
  scope :order_by_max_depth_asc, -> {add_max_depth.reorder("max_depth ASC")}

  attr_accessor :is_favourite

  def as_json(options={})
    super(options.merge({:methods => :type}))
  end

  public

  def self.create_tree(params, archived = false)
    # Ensure that the patient exists
    unless Patient.exists?(id: params[:patient_id])
      logger.error "Error: Patient doesn't exist"
      raise ActiveRecord::Rollback, ["#{I18n.t :error_invalid_patient_id}."]
    end

    if Tree.exists?(id: params[:id])
      logger.error "Tree already exists"
      raise ActiveRecord::Rollback, ["#{I18n.t :error_tree_already_exists}."]
    end

    # Acquire parameters, but don't care for pages. Pages will be handled later
    parameters = params.deep_dup
    parameters.delete(:pages)
    parameters.delete(:favourite)
    parameters.delete(:presentation_page)
    
    # Save nothing if something goes wrong
    Tree.transaction do
      tree = Tree.new(parameters)
      if archived
        tree.type = ArchivedTree
      else
        if parameters[:type]
          tree.type = parameters[:type]
        else
          tree.type = CustomTree
        end
      end

      # Now it's time to take care of pages
      # parameters = params[:pages].deep_dup

      parameters  = params.deep_dup
      
      pages, card_ids, page_layouts = extract_pages_cards_params( parameters, tree )

      # Now I can change all the pages ids.
      change_page_ids( tree, pages, card_ids, page_layouts )

      # Here I reorder pages to be sure that parents are created before their childrens
      pages = reorder_pages(pages)

      # Create pages
      ArchivedCardPage.create!(pages)

      # Create page layouts
      PageLayout.create!(page_layouts)

      # This is now commented because the parent-children relationship is now done in pages creation.
      # If no problems arise, this commented code can safely be deleted.
      # pages = Page.where(id: pages_ids).to_a.uniq
      # page_layouts.each do |layout|
      #   puts "layout -> #{layout.inspect}"
      #   next if layout[:next_page_id].blank?
      #   page = pages.detect{|p| p[:id] == layout[:next_page_id]}
      #   page.update(parent_id: layout[:page_id])
      # end

      create_presentation_page(tree, params[:presentation_page])

      if tree.save
        return tree
      else
        @errors = tree.errors.full_messages
        logger.error "Error: can't save Tree: #{tree.errors.full_messages}"
        raise ActiveRecord::Rollback, "#{I18n.t :error_cant_create_tree}"
      end
    end

    # If this code gets executed it means something went wrong with the transaction.
    logger.error "Error: #{@errors.inspect}"
    raise ActiveRecord::ActiveRecordError, @errors
  end

  # Returns a saved archived clone of the current tree. Pages, cards and contents will be duplicated.
  # Tags will be referenced.
  def get_a_clone
    new_tree = self.dup
    new_tree.id = SecureRandom.uuid()
    new_tree.root_page_id = self.root_page.get_a_clone(true).id
    new_tree = new_tree.becomes!(ArchivedTree)
    if new_tree.save
      return new_tree
    end
    logger.error "Error: can't clone the tree"
    raise ActiveRecord::Rollback, "Can't create a clone of the tree"
  end

  # Returns a saved archived clone of the current tree. Pages, cards and contents will be duplicated.
  # Tags will be referenced.
  def get_an_unsaved_clone
    new_tree = self.dup
    new_tree.id = SecureRandom.uuid()
    new_tree.root_page_id = self.root_page.get_a_clone(true).id
    new_tree.type = "ArchivedTree"
    return new_tree
  end

  def self.update_page_and_cards_ids(parameters)
    # No mapping as of now
    ids_mapping = {}
    # Look at every page
    parameters[:pages].each do |page|
      # Check if the current id has alredy been mapped to another.
      existent_mapping = ids_mapping[page[:id]]
      if existent_mapping.nil?
        # Wasn't mapped. Create a new id for this page.
        existent_mapping = SecureRandom.uuid()
        ids_mapping[page[:id].to_s] = existent_mapping
      end
      # Assign the new id to the page.
      page[:id] = existent_mapping
      # Now look at every card.
      page[:cards].each do |card|
        # Get the id of the requested next page.
        next_page_id = card[:next_page_id]
        next if next_page_id.nil?
        # Check if the requested next page was already mapped
        existent_mapping = ids_mapping[next_page_id]
        if existent_mapping.nil?
          # Wasn't mapped. Create an id now.
          existent_mapping = SecureRandom.uuid()
          ids_mapping[card[:next_page_id].to_s] = existent_mapping
        end
        card[:next_page_id] = existent_mapping
      end
    end

    return parameters
  end

  def max_page_depth
    self.root_page.subtree.maximum(:ancestry_depth)
  end

  private

  # Creates a PageLayout entry that describes how the card is positioned inside the page and remaps everything
  # to clones of the requested cards.
  def self.update_page_cards (page, page_cards)
    page_cards.each do |c|
      card = Card.find(c[:id])
      if card.nil?
        logger.error "Error: can't find Card"
        raise ActiveRecord::Rollback, "#{I18n.t :error_card_not_found}: #{c[:id]}."
      end
      new_card = card.get_a_clone
      pl = PageLayout.create(page_id: page[:id], card_id: new_card[:id], x_pos: c[:x_pos], y_pos: c[:y_pos], scale: c[:scale], next_page_id: c[:next_page_id], hidden_link: c[:hidden_link].nil??false:c[:hidden_link])
      unless pl.persisted?
        logger.error "Error: can't save PageLayout"
        raise ActiveRecord::Rollback, "Can't save the pageLayout: #{pl.errors.full_messages[0]}"
      end
    end
  end

  # Uses the existing tags whenever possibile.
  # If a tag didn't exist, it gets created.
  def self.manage_tags (page, page_tags)
    page.page_tags = []
    return if page_tags.blank?
    page_tags.each do |tag|
      tag.capitalize!
      found_tag = PageTag.where(tag: tag).first
      if found_tag.nil?
        found_tag = PageTag.new(tag: tag)
        found_tag[:id] = SecureRandom.uuid()
        found_tag.save!
      end
      if found_tag.nil?
        raise ActiveRecord::Rollback, "#{I18n.t :error_tag_not_found} #{tag}"
      end
      page.page_tags << found_tag
    end
  end

  def self.update_from_array( hash_array )
    hash_array.each do |record|
      obj = Tree.find(record[:id])
      obj.update(record)
      obj.save!
    end
  end

end
