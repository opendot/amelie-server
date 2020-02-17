class Api::V1::PagesController < ApplicationController
  def index
    pages = get_viewable_pages
    pages = pages.includes(page_layouts: [:card, :page])
    paginate json: pages, each_serializer: Api::V1::PageSerializer, per_page: 5, status: :ok
  end

  def show
    page = nil
    if params.has_key?(:type)
      page = params[:type].to_s.constantize.includes(:cards, :page_tags).find(params[:id])
    else
      page = Page.includes(:cards, :page_tags).find(params[:id])
    end
    render json: page, serializer: Api::V1::PageSerializer, status: :ok
  end

  def create
    Page.transaction do
      parameters = page_params

      # Remove all the parameters that don't belong to a page.
      parameters.delete(:cards)
      parameters.delete(:page_tags)

      # Create the new page.
      page = Page.create(parameters)

      # Update the position and the scale of the involved cards.
      # TODO: if the immutable pattern has to be followed, here is where you should
      # clone the selected cards into ArchivedCard objects.
      update_page_cards(page, page_params)

      # Now take care of the tags.
      manage_tags (page)

      if page.save
        render json: page, serializer: Api::V1::PageSerializer, status: :created
      else
        render json: {errors: page.errors.full_messages}, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end

  def update
    Page.transaction do
      parameters = page_params
      @cards = []
      page = Page.find(params[:id])

      if params.has_key?(:cards)
        # Duplicate the page and assign new cards
        page = page.update_with_cards(parameters)
      else
        # Don't need to duplicate the page
        page.update(parameters)
      end

      if page.save
        render json: page, serializer: Api::V1::PageSerializer, status: :accepted
      else
        render json: {errors: page.errors.full_messages}, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end

  def destroy
    Page.destroy(params[:id])
    render json: {success: true}, status: :ok
  end

  private

  def page_params
    params.permit(:id, :name, :patient_id, :background_color, :type, :page_tags =>[], :cards => [:id, :x_pos, :y_pos, :scale])
  end

  protected

  # TODO This method should be replaced by the one in the Page model.
  def update_page_cards(page, parameters)
    parameters[:cards].each do |c|
      card = Card.find(c[:id])
      if card.nil?
        render json: {errors: ["#{I18n.t :error_card_not_found}: #{c[:id]}."]}, status: :unprocessable_entity
        raise ActiveRecord::Rollback
        return
      end
      PageLayout.create(page_id: page.id, card_id: c[:id], x_pos: c[:x_pos], y_pos: c[:y_pos], scale: c[:scale])
    end
  end

  # TODO This method should be replaced by the one in the Page model.
  def manage_tags(page)
    page.page_tags = []
    if params.has_key?(:page_tags)
      params[:page_tags].each do |tag|
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
  end

  def get_viewable_pages
    if params.has_key?(:page_tag_id)
      pages = Tag.find(params[:page_tag_id]).pages
    else
      pages = Page.all
    end
    if params.has_key?(:type)
      pages = pages.where(type: params[:type])
    end
    return pages
  end
end
