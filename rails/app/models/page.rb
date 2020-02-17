class Page < ApplicationRecord
  extend TagCreation
  include Synchronizable
  
  has_ancestry :cache_depth => true

  has_and_belongs_to_many :page_tags, join_table: "pages_page_tags"
  has_many :page_layouts, dependent: :destroy
  has_many :cards, through: :page_layouts, dependent: :destroy
  has_many :page_children, class_name: 'Page', foreign_key: 'ancestry'
  belongs_to :patient, optional: true

  # Types are hardcoded in routes, but a validation is always a good thing to have.
  validates :type, inclusion: { in: %w(CustomPage PresetPage ArchivedCardPage ArchivedIdlePage FeedbackPage PresentationPage), message: "%{value} #{I18n.t :error_page_type}" }
  validates :type, presence: true

  default_scope { order(:created_at) }

  def as_json(options={})
    super(options.merge({:methods => [:type, :tags]}))
  end

  public
  
  # This method receives a hash representing a page with its linked cards (refer to page_params in pages_controller to see
  # the expected structure) and creates it. Linked cards will be cloned into ArchivedCard objects and the new page object
  # will be returned.
  def create_archived_page(page_hash)
    # do nothing if the page id is already in use
    if Page.exists?(id: page_hash[:id])
      raise ActiveRecord::Rollback, "The page id is already in use."
    end
    # Ensure to not leave zombie records in the database
    Page.transaction do
      parameters = page_hash.dup
      page_cards = page_hash[:cards].dup

      # Remove all the parameters that don't belong to a page.
      parameters.delete(:cards)
      parameters.delete(:page_tags)

      # Create the new page.
      page = ArchivedCardPage.create(parameters)

      # Check that the used cards exist and make a clone of them, then link the clone to the newly created page.
      page_cards.each do |c|
        card = Card.find(c[:id])
        if card.nil?
          raise ActiveRecord::Rollback, "Error searching a card: #{card.errors.full_messages}"
        end
        # Don't clone cards any more.
        # new_card = card.get_a_clone
        new_card = card
        pl = PageLayout.create(page_id: page.id, card_id: new_card[:id], x_pos: c[:x_pos], y_pos: c[:y_pos], scale: c[:scale], next_page_id: c[:next_page_id], hidden_link: c[:hidden_link].nil??false:c[:hidden_link])
        unless pl.persisted?
          raise ActiveRecord::Rollback, "Can't save the pageLayout: #{pl.errors.full_messages}"
        end
      end

      # Now take care of the tags.
      page.page_tags = []
      unless page_tags.blank?
        page_tags.each do |tag|
          tag.capitalize!
          found_tag = PageTag.where(tag: tag).first
          if found_tag.nil?
            found_tag = PageTag.new(tag: tag)
            found_tag[:id] = SecureRandom.uuid()
            found_tag.save!
          end
          if found_tag.nil?
            render json: {errors: ["#{I18n.t :error_tag_not_found} #{tag}"]}, status: :unprocessable_entity
            raise ActiveRecord::Rollback, "Card creation aborted"
            return
          end
          page.page_tags << found_tag
        end
      end

      if page.save
        return page
      else
        raise ActiveRecord::Rollback, "Can't save a page"
      end
    end
  end

  # This method creates a deep copy of a page and its cards. Will return a saved ArchivedPage object.
  def get_a_clone(clone_as_tree = false, parent_page_id = nil)
    # Ensure to not leave zombie records in the database
    Page.transaction do
      new_page = get_an_unsaved_clone()
      # Exclude from ancestry
      unless new_page.save
        raise ActiveRecord::Rollback, "Can't save the cloned page: #{page.errors.full_messages.inspect}"
      end
      unless parent_page_id.nil?
        new_page.parent_id = parent_page_id
      end
      # Get clones of the original cards and position them like the original ones
      self.page_layouts.includes(:card).each do |original_layout|
        new_card = original_layout.card
        if clone_as_tree && !original_layout[:next_page_id].blank?
          next_page = Page.find(original_layout[:next_page_id])
          next_page_id = nil
          unless next_page.nil?
            next_clone = next_page.get_a_clone(true, new_page.id)
            next_page_id = next_clone.id
          end

          page_layout = PageLayout.create(page_id: new_page.id, card_id: new_card[:id], type: original_layout[:type], x_pos: original_layout[:x_pos], y_pos: original_layout[:y_pos], scale: original_layout[:scale], selectable:original_layout[:selectable], correct: original_layout[:correct], next_page_id: next_page_id, hidden_link: original_layout[:hidden_link])
        else
          page_layout = PageLayout.create(page_id: new_page.id, card_id: new_card[:id], type: original_layout[:type], x_pos: original_layout[:x_pos], y_pos: original_layout[:y_pos], scale: original_layout[:scale], selectable:original_layout[:selectable], correct: original_layout[:correct], next_page_id: nil, hidden_link: original_layout[:hidden_link])
        end
        unless page_layout.persisted? && new_page.save
          raise ActiveRecord::Rollback, "Can't save the PageLayout of the cloned page: #{page_layout.errors.full_messages.inspect}"
        end
      end
      return new_page
    end
  end

  def get_an_unsaved_clone
    new_page = self.dup
    # Assign a new id.
    new_page.id = SecureRandom.uuid()
    # Make it an ArchivedCardPage
    new_page.type = "ArchivedCardPage"
    # Assign the tags
    new_page.page_tags = self.page_tags
    return new_page
  end

  # Update the cards and the page_layouts
  def update_with_cards(page_hash)
    # Duplicate the page and assign new cards
    clone = self.get_an_unsaved_clone
    clone.save!

    # Update with the given params, the type param is given by default by the route
    parameters = page_hash.dup
    parameters.delete(:id)
    parameters.delete(:cards)
    parameters.delete(:page_tags)

    clone.update!(parameters)

    page_hash[:cards].each do |card_param|
      # card_param = { :id, :x_pos, :y_pos, :scale }
      unless Card.exists?(card_param[:id])
        raise ActiveRecord::Rollback, "Can't find card #{card_param[:id]}"
      end

      selectable = card_param[:selectable]
      if selectable.nil? then selectable = true end 

      PageLayout.create!(page_id: clone.id, card_id: card_param[:id],
        x_pos: card_param[:x_pos], y_pos: card_param[:y_pos], scale: card_param[:scale],
        next_page_id: card_param[:next_page_id], selectable: selectable)
    end

    # archive current page
    self.update!(type: "ArchivedCardPage")

    return clone
  end

  def self.create(attributes=nil, &block)
    if attributes.is_a? Array
      return super
    end
    tags = attributes.include?(:tags) ? attributes[:tags].dup : nil
    attributes.delete(:tags)
    page = super
    unless tags.nil?
      my_tags = Page.create_tag_objects(tags, "PageTag")
      page.page_tags = my_tags
      page.save!
    end
    return page
  end

  def self.create!(attributes=nil, &block)
    self.create(attributes, &block)
  end

  def update(attributes)
    tags = attributes.include?(:tags) ? attributes[:tags].dup : nil
    attributes.delete(:tags)
    done = super
    return false unless done
    unless tags.nil?
      my_tags = Page.create_tag_objects(tags, "PageTag")
      self.page_tags = my_tags
      self.save!
    end
    return true
  end

  def update!(attributes)
    update(attributes)
  end

  # Export tags in the as_json, to allow the sync to create tags while creating a Page
  def tags
    self.page_tags.collect{|tag| tag[:tag]}
  end

  # Find all trees with this page
  def trees
    Tree.where(root_page_id: self.root_id)
  end

  # Find the id of the tree holding this page
  def tree_id
    self.trees.first.id
  end

  def update_from_array( hash_array )
    hash_array.each do |record|
      obj = Page.find(record[:id])
      obj.update(record)
      obj.save!
    end
  end

end
