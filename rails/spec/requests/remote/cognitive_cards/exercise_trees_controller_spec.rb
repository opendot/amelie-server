require 'rails_helper'
require 'shared/signin.rb'
require 'shared/tree_utils.rb'

describe Api::V1::CognitiveCards::ExerciseTreesController, :type => :request do
  include_context "signin"
  include_context "tree_utils"
  before(:all) do
      signin_researcher
  end

  context "index" do
    before(:each) do
      content = Text.create!(id: "content_on_many_exercises")
      @card = CognitiveCard.create!(id: "card_on_many_exercises", label: "Used a lot", level: 3, card_tag_ids: [CardTag.first.id], content_id: content.id)
      
      # Create some ExerciseTree with the cCognitiveCard
      target = Target.last
      @num_exercises = 3
      @num_exercises.times do |i|
        target.add_exercise_tree(
          create_exercise_tree_with_card( "cognitive_card_exercise_#{i}", "Exercise #{i}", @card),
          i+1
        )
      end

      get "/cognitive_cards/#{@card.id}/exercise_trees", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "return all ExerciseTree of the card" do
      trees = JSON.parse(response.body)
      expect(trees.length).to eq(@num_exercises)
    end
  end

end
