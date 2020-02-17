require 'rails_helper'
require 'shared/signin.rb'
require 'shared/tree_utils.rb'

describe Api::V1::Targets::ExerciseTreesController, :type => :request do
  include_context "signin"
  include_context "tree_utils"
  before(:all) do
      signin_researcher
  end

  context "index" do
    before(:each) do
      @target = Target.first
      get "/targets/#{@target.id}/exercise_trees", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "return only ExerciseTree" do
      trees = JSON.parse(response.body)
      trees.each do |tree|
        expect(tree["type"]).to eq("ExerciseTree")
      end
    end
  end

  context "create" do

    before(:each) do
      @target = Target.first

      @id = SecureRandom.uuid()
      @page_id = SecureRandom.uuid()
      @presentation_page_id = "presentation_page_update"
      @presentation_card = CognitiveCard.where(patient_id: nil).first
      tree = {
        id: @id, name: "New Exercise Tree",
        position: 1,
        pages: [
          get_page_hash_with_cards( @page_id, [
            get_page_layout_hash("card5", true),
          ], 0),
        ],
        presentation_page: get_page_hash_with_cards( @presentation_page_id, [
            get_page_layout_hash(@presentation_card.id, false),
          ], 2
        ),
      }

      post "/targets/#{@target.id}/exercise_trees", params: tree.to_json, headers: @headers
    end

    it "return 201 CREATED" do
      expect(response).to have_http_status(:created)
    end

    it "create the new tree" do
      created_tree = JSON.parse(response.body)
      expect(created_tree["id"]).to eq(@id)
    end

    it "changed the id of all pages" do
      created_tree = JSON.parse(response.body)
      expect(created_tree["pages"][0]["id"]).not_to eq(@page_id)
    end

    it "returned the presentaion page" do
      created_tree = JSON.parse(response.body)
      expect(created_tree["presentation_page"]["id"]).to eq(@presentation_page_id)
    end

    it "created the presentaion page" do
      expect(PresentationPage.exists?(@presentation_page_id)).to be true
    end

    it "cloned all cards of the presentation page" do
      presentation_page = PresentationPage.find(@presentation_page_id)
      expect(presentation_page.cards.exists?(@presentation_card.id)).to be false
    end

    it "has only archived cards in the  presentation page" do
      presentation_page = PresentationPage.find(@presentation_page_id)
      expect(presentation_page.cards.where.not(type: "ArchivedCard").count).to eq(0)
    end

  end


  context "create new box, target and exercise" do

    before(:each) do
      @patient = Patient.last
      @level = Level.first

      # In the backoffice, boxes are created as unpublisehd
      box_hash = {
        name: "New box",
        published: false,
      }
      post "/levels/#{@level.id}/boxes", params: box_hash.to_json, headers: @headers
      @box = Box.find(JSON.parse(response.body)["id"])

      # In the backoffice, targets are created as unpublisehd
      target_hash = {
        position: 1,
        name: "New target",
        published: false,
      }
      post "/boxes/#{@box.id}/targets", params: target_hash.to_json, headers: @headers
      @target = Target.find(JSON.parse(response.body)["id"])

      @id = SecureRandom.uuid()
      @page_id = SecureRandom.uuid()
      @presentation_page_id = "presentation_page_update"
      @presentation_card = CognitiveCard.where(patient_id: nil).first
      tree_hash = {
        id: @id, name: "New Exercise Tree",
        position: 1,
        pages: [
          get_page_hash_with_cards( @page_id, [
            get_page_layout_hash("card5", true),
          ], 0),
        ],
        presentation_page: get_page_hash_with_cards( @presentation_page_id, [
            get_page_layout_hash(@presentation_card.id, false),
          ], 2
        ),
      }

      post "/targets/#{@target.id}/exercise_trees", params: tree_hash.to_json, headers: @headers
      @exercise = ExerciseTree.find(JSON.parse(response.body)["id"])

      # Publish everything
      put "/boxes/#{@box.id}/targets/#{@target.id}", params: {published: true}.to_json, headers: @headers
      @target = Target.find(JSON.parse(response.body)["id"])

      put "/levels/#{@level.id}/boxes/#{@box.id}", params: {published: true}.to_json, headers: @headers
      @box = Box.find(JSON.parse(response.body)["id"])
    end

    it "has the correct exercise in the available_boxes" do
      available_box = AvailableBox.where(box_id: @box.id, patient_id: @patient.id).first
      expect(available_box.current_exercise_tree_id).to eq(@id)
    end

    it "remove the exercise from the available_boxes if I unpublish the exercise" do
      put "/targets/#{@target.id}/exercise_trees/#{@exercise.id}", params: {published: false}.to_json, headers: @headers

      available_box = AvailableBox.where(box_id: @box.id, patient_id: @patient.id).first
      expect(available_box.current_exercise_tree_id).to eq(nil)
    end

    it "has the correct exercise in the available_boxes if I unpublish and republish the exercise" do
      put "/targets/#{@target.id}/exercise_trees/#{@exercise.id}", params: {published: false}.to_json, headers: @headers
      put "/targets/#{@target.id}/exercise_trees/#{@exercise.id}", params: {published: true}.to_json, headers: @headers

      available_box = AvailableBox.where(box_id: @box.id, patient_id: @patient.id).first
      expect(available_box.current_exercise_tree_id).to eq(@id)
    end

  end

  context "create presentation page id" do
    before(:each) do
      @id = SecureRandom.uuid()
      @exercise = create_exercise_tree(@id, "presentation_page_updated")
      @target = Target.last
      @target.add_exercise_tree(@exercise)
      @cards_array = CognitiveCard.limit(3).to_a
      
      @new_presentation_page_id = "presentation_page_update"
      @new_presentation_page = create_presentation_page(@new_presentation_page_id, "Test")

      # Since the update create a new tree, I have to send the other params like in a CREATE
      tree = {
        id: @id, name: "New Exercise Tree",
        position: 1,
        pages: [
          get_page_hash_with_cards( @page_id, [
            get_page_layout_hash("card5", true),
          ], 0),
        ],
        presentation_page_id: @new_presentation_page_id,
      }

      post "/targets/#{@target.id}/exercise_trees", params: tree.to_json, headers: @headers
    end

    it "respond 422 UNPROCESSABLE ENTITY" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "return a valid error message" do
      tree = JSON.parse(response.body)
      expect(tree["errors"].length).to eq(3)
    end

    it "didn't updated the exercise tree" do
      tree = Tree.find(@id)
      expect(tree.type).to eq("ExerciseTree")
    end
  end

  context "update without pages" do
    before(:each) do
        @id = SecureRandom.uuid()
        @exercise = create_exercise_tree(@id, "to_be_updated")
        @target = Target.last
        @target.add_exercise_tree(@exercise)
        @new_name = "no_pages_updated"

        tree = {
            name: @new_name,
        }
        put "/targets/#{@target.id}/exercise_trees/#{@exercise.id}", params: tree.to_json, headers: @headers
    end

    it "respond 202 ACCEPTED" do
        expect(response).to have_http_status(:accepted)
    end

    it "return the updated exercise" do
        tree = JSON.parse(response.body)
        expect(tree["name"]).to eq(@new_name)
    end

    it "didn't created a new exercise" do
        tree = JSON.parse(response.body)
        expect(tree["id"]).to eq(@exercise.id)
    end

    it "return an exercise tree" do
        tree = Tree.find(JSON.parse(response.body)["id"])
        expect(tree.type).to eq("ExerciseTree")
    end

  end

  context "update with pages" do
    before(:each) do
      @id = SecureRandom.uuid()
      @exercise = create_exercise_tree(@id, "pages_updated")
      @target = Target.first
      @target.add_exercise_tree(@exercise)
      @cards_array = CognitiveCard.limit(3).to_a

      @available_boxes_count = AvailableBox.where(current_exercise_tree_id: @id).count
      @available_exercises_count = AvailableExerciseTree.where(exercise_tree_id: @id).count

      # Since the update create a new tree, I have to send the other params like in a CREATE
      tree = {
        name: @exercise.name,
        pages: [
          get_page_hash_with_cards( "new_page_1", [
            get_page_layout_hash(@cards_array[0].id, true, "new_page_2"),
            get_page_layout_hash(@cards_array[1].id, false),
          ], 0),
          get_page_hash_with_cards( "new_page_2", [
            get_page_layout_hash(@cards_array[2].id, true, "new_page_3"),
            get_page_layout_hash(@cards_array[0].id, false),
          ], 1),
          get_page_hash_with_cards( "new_page_3", [
            get_page_layout_hash(@cards_array[1].id, true),
            get_page_layout_hash(@cards_array[2].id, false),
          ], 2),
        ],
      }

      put "/targets/#{@target.id}/exercise_trees/#{@exercise.id}", params: tree.to_json, headers: @headers
    end

    it "respond 202 ACCEPTED" do
      expect(response).to have_http_status(:accepted)
    end

    it "return the updated exercise" do
      tree = JSON.parse(response.body)
      expect(tree["pages"].count).to eq(3)
    end

    it "created a new exercise" do
      tree = JSON.parse(response.body)
      expect(tree["id"]).to_not eq(@exercise.id)
    end

    it "return an exercise tree" do
      tree = Tree.find(JSON.parse(response.body)["id"])
      expect(tree.type).to eq("ExerciseTree")
    end

    it "archived the previous tree" do
      tree = Tree.find(@id)
      expect(tree.type).to eq("ArchivedTree")
    end

    it "has the correct number of pages" do
      tree = Tree.find(JSON.parse(response.body)["id"])
      expect(tree.root_page.subtree.count).to eq(3)
    end

    it "updated the available_exercise_trees" do
      tree = Tree.find(JSON.parse(response.body)["id"])
      expect(AvailableExerciseTree.where(exercise_tree_id: tree.id).count).to eq(@available_exercises_count)
    end

    it "updated the available_boxes" do
      tree = Tree.find(JSON.parse(response.body)["id"])
      expect(AvailableBox.where(current_exercise_tree_id: tree.id).count).to eq(@available_boxes_count)
    end

  end

  context "update presentation page" do
    before(:each) do
      @id = SecureRandom.uuid()
      @exercise = create_exercise_tree(@id, "presentation_page_updated")
      @target = Target.last
      @target.add_exercise_tree(@exercise)
      @cards_array = CognitiveCard.limit(3).to_a
      
      @new_presentation_page_id = "presentation_page_update"

      # Since the update create a new tree, I have to send the other params like in a CREATE
      tree = {
        name: @exercise.name,
        pages: [
          get_page_hash_with_cards( "new_page_1", [
            get_page_layout_hash(@cards_array[0].id, true, "new_page_2"),
            get_page_layout_hash(@cards_array[1].id, false),
          ], 0),
          get_page_hash_with_cards( "new_page_2", [
            get_page_layout_hash(@cards_array[2].id, true, "new_page_3"),
            get_page_layout_hash(@cards_array[0].id, false),
          ], 1),
          get_page_hash_with_cards( "new_page_3", [
            get_page_layout_hash(@cards_array[1].id, true),
            get_page_layout_hash(@cards_array[2].id, false),
          ], 2),
        ],
        presentation_page: get_page_hash_with_cards( @new_presentation_page_id, [
            get_page_layout_hash(ArchivedCard.where(patient_id: nil).first.id, false),
          ], 2
        ),
      }

      put "/targets/#{@target.id}/exercise_trees/#{@exercise.id}", params: tree.to_json, headers: @headers
    end

    it "respond 202 ACCEPTED" do
      expect(response).to have_http_status(:accepted)
    end

    it "return the updated exercise" do
      tree = JSON.parse(response.body)
      expect(tree["presentation_page"]["id"]).to eq(@new_presentation_page_id)
    end

    it "created a new exercise" do
      tree = JSON.parse(response.body)
      expect(tree["id"]).to_not eq(@exercise.id)
    end

    it "return an exercise tree" do
      tree = Tree.find(JSON.parse(response.body)["id"])
      expect(tree.type).to eq("ExerciseTree")
    end

    it "archived the previous tree" do
      tree = Tree.find(@id)
      expect(tree.type).to eq("ArchivedTree")
    end

    it "created the new PresentationPage" do
      expect(PresentationPage.exists?(@new_presentation_page_id)).to be true
    end
  end

  context "update presentation page id" do
    before(:each) do
      @id = SecureRandom.uuid()
      @exercise = create_exercise_tree(@id, "presentation_page_updated")
      @target = Target.last
      @target.add_exercise_tree(@exercise)
      @cards_array = CognitiveCard.limit(3).to_a
      
      @new_presentation_page_id = "presentation_page_update"
      @new_presentation_page = create_presentation_page(@new_presentation_page_id, "Test")

      # Since the update create a new tree, I have to send the other params like in a CREATE
      tree = {
        name: @exercise.name,
        pages: [
          get_page_hash_with_cards( "new_page_1", [
            get_page_layout_hash(@cards_array[0].id, true, "new_page_2"),
            get_page_layout_hash(@cards_array[1].id, false),
          ], 0),
          get_page_hash_with_cards( "new_page_2", [
            get_page_layout_hash(@cards_array[2].id, true, "new_page_3"),
            get_page_layout_hash(@cards_array[0].id, false),
          ], 1),
          get_page_hash_with_cards( "new_page_3", [
            get_page_layout_hash(@cards_array[1].id, true),
            get_page_layout_hash(@cards_array[2].id, false),
          ], 2),
        ],
        presentation_page_id: @new_presentation_page_id,
      }

      put "/targets/#{@target.id}/exercise_trees/#{@exercise.id}", params: tree.to_json, headers: @headers
    end

    it "respond 422 UNPROCESSABLE ENTITY" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "return a valid error message" do
      tree = JSON.parse(response.body)
      expect(tree["errors"].length).to eq(3)
    end

    it "didn't updated the exercise tree" do
      tree = Tree.find(@id)
      expect(tree.type).to eq("ExerciseTree")
    end
  end

  context "update pages order" do
    before(:each) do
      @id = SecureRandom.uuid()
      @exercise = create_exercise_tree_with_pages(@id, "original_order", 3)
      presentation_page = create_presentation_page( "presentation_order", "Change page order")
      @exercise.update!(presentation_page_id: presentation_page.id)
      @target = Target.last
      @target.add_exercise_tree(@exercise)
      @cards_array = CognitiveCard.limit(3).to_a
      
      # Change page order
      @page_ids = @exercise.root_page.subtree_ids.to_a
      @new_page_1 = get_page_hash_from_existing(@page_ids[1])
      @new_page_2 = get_page_hash_from_existing(@page_ids[0])
      @new_page_3 = get_page_hash_from_existing(@page_ids[2])

      # Change next_page_id
      @new_page_1[:level] = 0
      @new_page_1[:cards].each do |card_hash|
        card_hash[:next_page_id] = @new_page_2[:id]
      end
      @new_page_2[:level] = 1
      @new_page_2[:cards].each do |card_hash|
        card_hash[:next_page_id] = @new_page_3[:id]
      end
      @new_page_3[:level] = 2
      @new_page_3[:cards].each do |card_hash|
        card_hash[:next_page_id] = nil
      end

      presentation_page_hash = get_page_hash_from_existing(@exercise.presentation_page_id)
      presentation_page_hash[:id] = SecureRandom.uuid()

      # Since the update create a new tree, I have to send the other params like in a CREATE
      tree = {
        name: @exercise.name,
        position: 5,
        pages: [
          @new_page_1, @new_page_2, @new_page_3
        ],
        presentation_page: presentation_page_hash,
      }

      put "/targets/#{@target.id}/exercise_trees/#{@exercise.id}", params: tree.to_json, headers: @headers
    end

    it "respond 202 ACCEPTED" do
      expect(response).to have_http_status(:accepted)
    end

    it "return the updated exercise" do
      tree = JSON.parse(response.body)
      expect(Tree.find(tree["id"]).root_page.name).to eq(@new_page_1[:name])
    end

    it "return the pages with the correct level" do
      tree = JSON.parse(response.body)
      pages = tree["pages"]
      pages.each do |page|
        original_page_hash = nil
        if page["name"] == @new_page_1[:name]
          original_page_hash = @new_page_1
        elsif page["name"] == @new_page_2[:name]
          original_page_hash = @new_page_2
        elsif page["name"] == @new_page_3[:name]
          original_page_hash = @new_page_3
        end

        expect(page["level"]).to eq(original_page_hash[:level])
      end
    end

    it "return the pages in the correct order" do
      tree = JSON.parse(response.body)

      expect(tree["pages"][0]["name"]).to eq(@new_page_1[:name])
      expect(tree["pages"][1]["name"]).to eq(@new_page_2[:name])
      expect(tree["pages"][2]["name"]).to eq(@new_page_3[:name])
    end

    it "created a new exercise" do
      tree = JSON.parse(response.body)
      expect(tree["id"]).to_not eq(@exercise.id)
    end

  end

  context "update consecutive_conclusions_required" do
    before(:each) do
      @id = SecureRandom.uuid()
      @exercise = create_exercise_tree(@id, "presentation_page_updated")
      @target = Target.last
      @target.add_exercise_tree(@exercise)

      @new_count = 4
    end

    context "without pages" do
      before(:each) do
        @cards_array = CognitiveCard.limit(3).to_a

        tree = {
          consecutive_conclusions_required: @new_count,
        }

        put "/targets/#{@target.id}/exercise_trees/#{@exercise.id}", params: tree.to_json, headers: @headers
      end

      it "change the value in the available_exercise with patient nil" do
        expect(AvailableExerciseTree.where(exercise_tree_id: @exercise.id, patient_id: nil).first.consecutive_conclusions_required).to eq(@new_count)
      end

      it "updated the count in all available_exercises" do
        expect(AvailableExerciseTree.where(exercise_tree_id: @exercise.id).where.not(consecutive_conclusions_required: @new_count).count).to eq(0)
      end

      it "update the count every time" do
        [2, 5, 10, 3].each do |i|
          put "/targets/#{@target.id}/exercise_trees/#{@exercise.id}", params: {consecutive_conclusions_required: i}.to_json, headers: @headers

          expect(AvailableExerciseTree.where(exercise_tree_id: @exercise.id, patient_id: nil).first.consecutive_conclusions_required).to eq(i)
          expect(AvailableExerciseTree.where(exercise_tree_id: @exercise.id).where.not(consecutive_conclusions_required: i).count).to eq(0)
        end
      end

    end

    context "with pages" do
      before(:each) do
        @cards_array = CognitiveCard.limit(3).to_a

        # Since the update create a new tree, I have to send the other params like in a CREATE
        tree = {
          name: @exercise.name,
          consecutive_conclusions_required: @new_count,
          pages: [
            get_page_hash_with_cards( "new_page_1", [
              get_page_layout_hash(@cards_array[0].id, true, "new_page_2"),
              get_page_layout_hash(@cards_array[1].id, false),
            ], 0),
            get_page_hash_with_cards( "new_page_2", [
              get_page_layout_hash(@cards_array[2].id, true, "new_page_3"),
              get_page_layout_hash(@cards_array[0].id, false),
            ], 1),
            get_page_hash_with_cards( "new_page_3", [
              get_page_layout_hash(@cards_array[1].id, true),
              get_page_layout_hash(@cards_array[2].id, false),
            ], 2),
          ],
        }

        put "/targets/#{@target.id}/exercise_trees/#{@exercise.id}", params: tree.to_json, headers: @headers
        @updated_tree = JSON.parse(response.body)
      end

      it "change the value in the available_exercise with patient nil" do
        expect(AvailableExerciseTree.where(exercise_tree_id: @updated_tree["id"], patient_id: nil).first.consecutive_conclusions_required).to eq(@new_count)
      end

      it "updated the count in all available_exercises" do
        expect(AvailableExerciseTree.where(exercise_tree_id: @updated_tree["id"]).where.not(consecutive_conclusions_required: @new_count).count).to eq(0)
      end

      it "update the count every time" do
        updated_tree = @updated_tree
        [2, 5, 10, 3].each do |i|
          tree = {
            name: @exercise.name,
            consecutive_conclusions_required: i,
            pages: [
              get_page_hash_with_cards( "new_page_1_#{i}", [
                get_page_layout_hash(@cards_array[0].id, true, "new_page_2_#{i}"),
                get_page_layout_hash(@cards_array[1].id, false),
              ], 0),
              get_page_hash_with_cards( "new_page_2_#{i}", [
                get_page_layout_hash(@cards_array[2].id, true, "new_page_3_#{i}"),
                get_page_layout_hash(@cards_array[0].id, false),
              ], 1),
              get_page_hash_with_cards( "new_page_3_#{i}", [
                get_page_layout_hash(@cards_array[1].id, true),
                get_page_layout_hash(@cards_array[2].id, false),
              ], 2),
            ],
          }
          put "/targets/#{@target.id}/exercise_trees/#{updated_tree["id"]}", params: tree.to_json, headers: @headers
          updated_tree = JSON.parse(response.body)
          
          expect(AvailableExerciseTree.where(exercise_tree_id: updated_tree["id"], patient_id: nil).first.consecutive_conclusions_required).to eq(i)
          expect(AvailableExerciseTree.where(exercise_tree_id: updated_tree["id"]).where.not(consecutive_conclusions_required: i).count).to eq(0)
        end
      end

    end

  end

end
