class Api::V1::CognitiveCards::ExerciseTreesController < Api::V1::TreesController
  include I18nSupport
  before_action :set_cognitive_card

  # GET /cognitive_cards/:cognitive_card_id/exercise_trees
  # List of all exercise_trees that contains the cognitive card
  def index
    # Get all root pages that have the cognitive card
    root_page_ids = @cognitive_card.pages.where(ancestry: nil).select(:id)
    
    # Get all non-root pages that have the cognitive card, use the ancestry column to obtain the root_page_id
    root_page_ids_2 = @cognitive_card.pages.where.not(ancestry: nil).select(:ancestry).map {|page| page.ancestry.split("/")[0]}

    # Get all exercise_trees that have a root_page included in the 2 lists
    exercise_trees = ExerciseTree.where(:root_page_id => root_page_ids)
    .or(ExerciseTree.where(:root_page_id => root_page_ids_2))
    .base_params.with_position

    paginate json: exercise_trees, each_serializer: Api::V1::Targets::ListExerciseTreeSerializer, status: :ok, per_page: 25
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cognitive_card
      # Check cognitive card existence
      unless CognitiveCard.exists?(params[:cognitive_card_id])
        render json: {errors: [I18n.t("error"), "id: #{params[:cognitive_card_id]}"]}, status: :not_found
        return
      end
      @cognitive_card = CognitiveCard.find(params[:cognitive_card_id])
    end

end
