class Api::V1::LoadTreeEventsController < Api::V1::SessionEventsController

  before_action :check_exercise_tree, :check_one_session_per_box_a_day, only: [:create]

  def broadcast_event_message
    # This time it's unuseful to broadcast messages.
  end

  protected

  def session_event_params
    params.merge(tree_id: params[:tree][:id]).permit(:id, :type, :training_session_id, :tree_id, tree: [:id, :name, :favourite, :patient_id, pages: [:id, :name, :level, :background_color, :page_tags => [], cards:[:id, :x_pos, :y_pos, :scale, :next_page_id, :selectable, :hidden_link]]])
  end

  def filter_parameters
    parameters = session_event_params.deep_dup
    parameters.delete(:tree)
    return parameters
  end

  def on_event_created
    # If the tree id is supplied it means that the tree is already saved in the database
    tree_id = session_event_params[:tree][:id]
    if tree_id.blank?
      parameters = session_event_params[:tree]
      parameters = parameters.merge(id: SecureRandom.uuid())
      # Won't catch the exception. It will be catched in SessionEventsController#create
      tree = Tree.create_tree(parameters, true)
      if tree.nil?
        logger.error "Error: Tree hasn't been created"
        return false
      end
    else
      if params[:training_session_id].to_s.start_with?('preview_')
        if params[:tree][:id].nil?
          parameters = session_event_params[:tree]
          parameters[:id] = SecureRandom.uuid()
          parameters[:type] = "PreviewTree"
          tree = Tree.create_tree(parameters, false)
        else
          tree = Tree.find(params[:tree][:id])
          cloned = tree.get_an_unsaved_clone
          cloned.id = SecureRandom.uuid()
          cloned[:type] = "PreviewTree"
          tree = cloned
          tree.save!
        end
      else
        tree = Tree.find(tree_id)
        if tree.nil?
          logger.error "Error: Tree not found"
          return false
        end
        tree = tree.get_a_clone
      end
    end

    if tree.presentation_page_id.nil?
      TransitionToPageEvent.create!(next_page_id: tree.root_page_id, training_session_id: params[:training_session_id])
    else
      presentation = tree.presentation_page.get_a_clone_with_next_page(tree.root_page_id)
      transition_event = TransitionToPresentationPageEvent.create!(next_page_id: presentation.id, training_session_id: params[:training_session_id])
      transition_event.broadcast_transition_to_page_message(tree.root_page_id)
    end

    return true
  end

  private

  def check_exercise_tree
    cognitive_session = CognitiveSession.find_by(id: params[:training_session_id])

    unless cognitive_session.nil? 
      unless ExerciseTree.exists?(params[:tree][:id])
        return render json: {errors: [I18n.t("error_load_tree_missing_exercise_tree", "tree.id: #{params[:tree][:id]}")]}, status: :unprocessable_entity
      end
    end
  end

  # In CognitiveSessions a patient can repeat an Exercise only once a day,
  # so a patient can access a Box only once a day
  def check_one_session_per_box_a_day
    cognitive_session = CognitiveSession.find_by(id: params[:training_session_id])

    unless cognitive_session.nil? 
      exercise_tree = ExerciseTree.find_by(id: params[:tree][:id])

      unless exercise_tree.nil?
        available_box = exercise_tree.available_box_for(cognitive_session.patient_id)

        if !available_box.last_completed_exercise_tree_at.nil? && available_box.last_completed_exercise_tree_at.today?
          return render json: {errors: [I18n.t("error_one_exercise_a_day")]}, status: :unauthorized
        end

      end
    end
  end

end
