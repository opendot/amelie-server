RSpec.configure do |rspec|
    # This config option will be enabled by default on RSpec 4,
    # but for reasons of backwards compatibility, you have to
    # set it on RSpec 3.
    #
    # It causes the host group and examples to inherit metadata
    # from the shared context.
    rspec.shared_context_metadata_behavior = :apply_to_host_groups
  end
  
  RSpec.shared_context "cognitive_session_utils", :shared_context => :metadata do
  
    def message_disable_socket
      "These tests will fail if the POST try to send a message on socket."
    end

    def create_only_cognitive_session id
      cloned_tracker_calibration_param = @patient.tracker_calibration_parameter.get_a_clone
      session = CognitiveSession.create!(
        id: id,
        user: @user, patient: @patient,
        start_time: DateTime.now, tracker_calibration_parameter_id: cloned_tracker_calibration_param.id
      )
      cloned_tracker_calibration_param.update!(training_session: session)
      return session
    end

    def create_cognitive_session id, exercise
      session = create_only_cognitive_session(id)

      LoadTreeEvent.create!(training_session: session, tree_id: exercise.id)
        root_page_event = TransitionToPageEvent.new(training_session: session, next_page_id: exercise.root_page_id)
        root_page_event.skip_broadcast_callback = true
        root_page_event.save!

      return session
    end

    def answer_all_questions session, exercise, correct
      page = exercise.root_page
      while !page.nil? do
        wrong_layout = page.page_layouts.where(correct: correct).first

        if wrong_layout.nil?
          # This should never happen
          page = nil
        else
          # Select the correct answer
          next_page_id = wrong_layout.next_page_id
          PatientEyeChoiceEvent.create!(training_session: session, page_id: page.id, card_id: wrong_layout.card_id)

          if next_page_id.nil?
            page = nil
          else
            next_page_event = TransitionToPageEvent.new(training_session: session,
              page: page, card_id: wrong_layout.card_id, next_page_id: next_page_id)
            next_page_event.skip_broadcast_callback = true
            next_page_event.save!
            page = Page.find(next_page_id)
          end
        end
      end
    end

    def answer_n_questions session, start_page, n, correct
      page = start_page
      count = 0
      while !page.nil? && count < n do
        layout = page.page_layouts.where(correct: correct).first

        if layout.nil?
          # This should never happen
          page = nil
        else
          # Select the correct answer
          next_page_id = layout.next_page_id
          PatientEyeChoiceEvent.create!(training_session: session, page_id: page.id, card_id: layout.card_id)
          count += 1

          if next_page_id.nil?
            page = nil
          else
            next_page_event = TransitionToPageEvent.new(training_session: session,
              page: page, card_id: layout.card_id, next_page_id: next_page_id)
            next_page_event.skip_broadcast_callback = true
            next_page_event.save!
            page = Page.find(next_page_id)
          end
        end
      end
      return page
    end

    def conclude_session session
      transition_to_end = TransitionToEndEvent.new(training_session: session, page: nil)
      transition_to_end.skip_broadcast_callback = true
      transition_to_end.save!
      session.calculate_duration
    end

    def create_and_conclude_session id, exercise, correct
      session = create_cognitive_session id, exercise
      answer_all_questions session, exercise, correct
      conclude_session session
      return session
    end

    def create_and_interrupt_session id, exercise, num_answers
      session = create_cognitive_session id, exercise
      answer_n_questions session, exercise.root_page, num_answers, true
      conclude_session session
      return session
    end

    def allow_to_repeat_exercise exercise, patient
      # An exercise can be executed only once a day, change the date of last completed exercise
      exercise.available_box_for(patient.id).update!(last_completed_exercise_tree_at: 3.days.ago)
    end
  
  end
  
  RSpec.configure do |rspec|
    rspec.include_context "cognitive_session_utils", :include_shared => true
  end