class FeedbackPage < MutablePage
  extend TagCreation
  include ExtraPage
  # Page used to show a feedback during a CognitiveSession
  # Use the tags to find different type of pages

  has_and_belongs_to_many :feedback_tags, join_table: "feedback_pages_feedback_tags"
  has_many :page_layouts, dependent: :destroy, foreign_key: "page_id", after_add: :set_card_not_selectable
  
  has_many :trees, foreign_key: 'strong_feedback_page_id'

  FILTERS = ["positive", "negative", "strong"].freeze

  default_scope { reorder(created_at: :desc) }

  class << self
    FILTERS.each do |filter_name|

      define_method "#{filter_name}" do
        FeedbackTag.includes(:feedback_pages).find_by_tag(filter_name).feedback_pages
      end

      define_method "positive_#{filter_name}" do
        FeedbackTag.includes(:feedback_pages).find_by_tag("positive").feedback_pages.where(id: FeedbackTag.includes(:feedback_pages).find_by_tag(filter_name).feedback_pages)
      end

      define_method "negative_#{filter_name}" do
        FeedbackTag.includes(:feedback_pages).find_by_tag("negative").feedback_pages.where(id: FeedbackTag.includes(:feedback_pages).find_by_tag(filter_name).feedback_pages)
      end

      define_method "strong_#{filter_name}" do
        FeedbackTag.includes(:feedback_pages).find_by_tag("strong").feedback_pages.where(id: FeedbackTag.includes(:feedback_pages).find_by_tag(filter_name).feedback_pages)
      end

      define_method "#{filter_name}_random" do
        feedback_pages = FeedbackTag.includes(:feedback_pages).find_by_tag(filter_name).feedback_pages
        return feedback_pages.offset(rand(feedback_pages.size))
      end

    end
  end

  def self.create(attributes=nil, &block)
    if attributes.is_a? Array
      return super
    end
    tags = attributes.include?(:tags) ? attributes[:tags].dup : nil
    attributes.delete(:tags)
    feedback_page = super
    unless tags.nil?
      my_tags = Page.create_tag_objects(tags, "FeedbackTag")
      feedback_page.feedback_tags = my_tags
      feedback_page.save!
    end
    return feedback_page
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
      my_tags = Page.create_tag_objects(tags, "FeedbackTag")
      self.feedback_tags = my_tags
      self.save!
    end
    return true
  end

  def update!(attributes)
    update(attributes)
  end

  # Update the cards and the page_layouts
  def update_with_cards(page_hash)
    # The Feedback page doesn't need a duplication
    # It's only used in a cognitive session, and in that case
    # it's used a clone of this page

    # Update with the given params, the type param is given by default by the route
    parameters = page_hash.dup
    parameters.delete(:id)
    parameters.delete(:cards)
    parameters.delete(:page_tags)

    self.update!(parameters)

    # Destroy and recreate links with the cards
    self.page_layouts.destroy_all
    
    page_hash[:cards].each do |card_param|
      # card_param = { :id, :x_pos, :y_pos, :scale }
      unless Card.exists?(card_param[:id])
        raise ActiveRecord::Rollback, "Can't find card #{card_param[:id]}"
      end

      selectable = card_param[:selectable]
      if selectable.nil? then selectable = false end 

      PageLayout.create!(page_id: self.id, card_id: card_param[:id],
        x_pos: card_param[:x_pos], y_pos: card_param[:y_pos], scale: card_param[:scale],
        next_page_id: card_param[:next_page_id], selectable: selectable)
    end

    return FeedbackPage.find(self.id)
  end

  def tags
    self.feedback_tags.collect{|tag| tag[:tag]}
  end

end