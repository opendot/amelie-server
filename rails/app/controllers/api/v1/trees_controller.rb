class Api::V1::TreesController < ApplicationController
  before_action :check_id_presence, only: [:create]

  def create
    begin
      parameters = tree_params
      parameters[:user_id] = current_user[:id]
      tree = Tree.create_tree(parameters, false)
      favourite = false
      if params.has_key?(:favourite)
        favourite = params[:favourite]
      end
      if tree.valid?
        UserTree.create(id: SecureRandom.uuid(), user_id: current_user[:id], tree_id: tree[:id], favourite: favourite)
      end
      tree.is_favourite = favourite
      render json: tree, serializer: Api::V1::TreeSerializer, status: :created
    rescue => exception
      render json: {errors: JSON.parse(exception.message)}, status: :unprocessable_entity
    end
  end

  # As we ar following the immutable pattern, update is really a soft delete followed by a creation.
  def update
    parameters = tree_params
    # If there are pages I suppose to have here all the infos I need.
    # If pages aren't present, I suppose to have a tree id indicating a tree to be cloned.
    if params.has_key?(:pages)
      
      parameters[:id] = SecureRandom.uuid()
      parameters[:user_id] = current_user[:id]
      #parameters = Tree.update_page_and_cards_ids(parameters)
      begin
        # Create a new tree
        tree_ok = Tree.create_tree(parameters, false)
        # Archive the old one
        tree = Tree.find(params[:id])
        tree.update(type:"ArchivedTree")
        user_tree = UserTree.find_by(tree_id: params[:id])
        user_tree.destroy unless user_tree.nil?
      rescue => exception
        render json: {errors: [exception.message]}, status: :unprocessable_entity
        return
      end
      favourite = false
      if params.has_key?(:favourite)
        favourite = params[:favourite]
      end
      if tree_ok.valid?
        UserTree.create(id: SecureRandom.uuid(), user_id: current_user[:id], tree_id: tree_ok[:id], favourite: favourite)
      end
      tree_ok.is_favourite = favourite
      render json: tree_ok, serializer: Api::V1::TreeSerializer, status: :accepted
    else
      parameters.delete(:patient_id)
      parameters.delete(:favourite)
      tree = Tree.find(params[:id])
      if tree.update(parameters)
        favourite = false
        if params.has_key?(:favourite)
          favourite = params[:favourite]
        end
        user_tree = UserTree.find_by(tree_id: params[:id])
        user_tree.destroy unless user_tree.nil?
        UserTree.create(id: SecureRandom.uuid(), user_id: current_user[:id], tree_id: tree[:id], favourite: favourite)
        tree.is_favourite = favourite
        render json: tree, serializer: Api::V1::SimpleTreeSerializer, status: :accepted
      else
        render json: {errors: tree.errors.full_messages}, status: :unprocessable_entity
      end
    end
  end

  def index
    # Trees are indexable only on a per-patient basis.
    if !params.has_key?(:patient_id) || params[:patient_id].blank?
      render json: {errors: ["#{I18n.t :error_missing_patient_id}."]}, status: :unprocessable_entity
      return
    end
    trees = Tree.where(patient_id: params[:patient_id])
    if params.has_key?(:type)
      trees = trees.where(type: params[:type])
    end
    if params.has_key?(:only_favourites) && params[:only_favourites] == "true"
      favourite_ids = UserTree.joins(:tree).where(user_id: current_user[:id], favourite: true).pluck(:tree_id)
      trees = trees.where(id: favourite_ids).where(patient_id: params[:patient_id])
    end
    if params.has_key?(:query)
      trees = trees.where("name LIKE :query", query: "#{params[:query]}%").order(:name)
    end
    trees = paginate trees.includes(root_page: [:page_children]).to_a
    trees.each do |tree|
      user_tree = UserTree.find_by(user_id: current_user[:id], tree_id: tree[:id])
      tree.is_favourite = false
      unless user_tree.nil?
        tree.is_favourite = user_tree[:favourite]
      end
    end
    render json: trees, each_serializer: Api::V1::SimpleTreeSerializer, status: :ok
  end

  def show
    tree = Tree.includes(root_page:[:cards, page_children:[:cards, page_layouts:[:card]], page_layouts:[:card]]).find(params[:id])
    user_tree = UserTree.find_by(user_id: current_user[:id], tree_id: tree[:id])
    tree.is_favourite = false
    unless user_tree.nil?
      tree.is_favourite = user_tree[:favourite]
    end
    render json: tree, serializer: Api::V1::TreeSerializer, status: :ok
  end

  def destroy
    render json: {errors: ["#{I18n.t :error_cant_delete_tree}"]}, status: :locked
  end

  private

  def tree_params
    params.permit(:id, :name, :favourite, :patient_id, pages: [:id, :name, :level, :background_color, :page_tags => [], cards:[:id, :x_pos, :y_pos, :scale, :next_page_id, :selectable, :hidden_link]],
      presentation_page: [:id, :name, :level, :background_color, :page_tags => [], cards:[:id, :x_pos, :y_pos, :scale]]
    )
  end

  # Creates a PageLayout entry that describes how the card is positioned inside the page and remaps everything
  # to clones of the requested cards.
  def update_page_cards(page, page_cards)
    page_cards.each do |c|
      card = Card.find(c[:id])
      if card.nil?
        render json: {errors: ["#{I18n.t :error_card_not_found}: #{c[:id]}."]}, status: :unprocessable_entity
        raise ActiveRecord::Rollback, "Error searching a card: #{card.errors.full_messages}"
        return
      end
      new_card = card.get_a_clone
      pl = PageLayout.create(page_id: page.id, card_id: new_card[:id], x_pos: c[:x_pos], y_pos: c[:y_pos], scale: c[:scale], next_page_id: c[:next_page_id], hidden_link: c[:hidden_link].nil??false:c[:hidden_link])
      unless pl.persisted?
        raise ActiveRecord::Rollback, "Can't save the pageLayout: #{pl.errors.full_messages}"
      end
    end
  end

  # Uses the existing tags whenever possibile.
  # If a tag didn't exist, it gets created.
  def manage_tags(page, page_tags)
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
        render json: {errors: ["#{I18n.t :error_tag_not_found} #{tag}"]}, status: :unprocessable_entity
        raise ActiveRecord::Rollback, "Card creation aborted"
        return
      end
      page.page_tags << found_tag
    end
  end

  # Show a valid message if the id is missing
  def check_id_presence
    unless params.has_key?(:id)
      return render json: {errors: [I18n.t(:error_cant_create_tree), I18n.t(:error_missing_id)]}, status: :unprocessable_entity
    end
  end
end
