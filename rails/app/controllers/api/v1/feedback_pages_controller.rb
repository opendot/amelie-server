class Api::V1::FeedbackPagesController < Api::V1::PagesController
  include I18nSupport

  # POST feedback_pages
  def create
    FeedbackPage.transaction do
      parameters = page_params

      # Remove all the parameters that don't belong to a page.
      parameters.delete(:cards)

      # Create the new page.
      page = FeedbackPage.create(parameters)

      # Update the position and the scale of the involved cards.
      # TODO: if the immutable pattern has to be followed, here is where you should
      # clone the selected cards into ArchivedCard objects.
      update_page_cards(page, page_params)

      # Now take care of the tags.
      manage_tags(page)

      if page.save
        render json: page, serializer: Api::V1::FeedbackPageSerializer, status: :created
      else
        render json: {errors: page.errors.full_messages}, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end

  # GET feedback_pages/:id?next_page_id=:next_page_id
  def show
    page = Page.includes(:cards, :page_tags).find_by(id: params[:id])
    if page.nil?
      return render json: {errors: ["#{I18n.t :error_invalid_page_id} #{params[:id]}"]}, status: :not_found
    end

    
    if page.type == "FeedbackPage" && !params[:next_page_id].nil?
      # Replace the next_page_id for all cards
      serialized_page = JSON.parse(Api::V1::PageSerializer.new(page).to_json)
      serialized_page["cards"].each do |card|
        card["next_page_id"] = params[:next_page_id]
      end

      return render json: serialized_page, adapter: nil, status: :ok
    end
    
    # This is an ArchivedPage, a clone of an existing FeedbackPage, with the next_page id already defined
    # or it's a FeedbackPage where tha params :next_page_id wasn't defined
    if page.type == "FeedbackPage"
      render json: page, serializer: Api::V1::FeedbackPageSerializer, status: :ok
    else
      render json: page, serializer: Api::V1::PageSerializer, status: :ok
    end
  end

  protected

  def page_params
    params.permit(:id, :name, :patient_id, :background_color, :type, :tags =>[], :cards => [:id, :x_pos, :y_pos, :scale])
  end
  
  def get_viewable_pages
    if params.has_key?(:tag)
      feedback_tag = FeedbackTag.includes(:feedback_pages).find_by_tag(params[:tag])
      if feedback_tag.nil?
        # return an empty array
        pages = FeedbackPage.where(:id => [])
      else
        pages = feedback_tag.feedback_pages
      end
    else
      pages = FeedbackPage.all
    end

    # Search from tag or label
    if params.has_key?(:search)
      pages = pages.left_outer_joins(:page_tags).group(:id)
      pages = pages.where("name LIKE :query", query: "#{params[:search]}%")
        .or(pages.where("tag LIKE :query", query: "#{params[:search]}%"))
    end
    return pages
  end

  def manage_tags(page)
    page.feedback_tags = []
    if params.has_key?(:tags)
      params[:tags].each do |tag|
        tag.capitalize!
        found_tag = FeedbackTag.where(tag: tag).first
        if found_tag.nil?
          found_tag = FeedbackTag.new(tag: tag)
          found_tag[:id] = SecureRandom.uuid()
          found_tag.save!
        end
        if found_tag.nil?
          render json: {errors: ["#{I18n.t :error_tag_not_found} #{tag}"]}, status: :unprocessable_entity
          raise ActiveRecord::Rollback, "Card creation aborted"
          return
        end
        page.feedback_tags << found_tag
      end
    end
  end

end