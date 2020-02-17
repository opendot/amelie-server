require 'rails_helper'
require 'shared/signin.rb'

describe Api::V1::CognitiveCardsController, :type => :request do
  include_context "signin"
  before(:all) do
    signin_researcher
  end

  context "create" do
    before(:each) do
      @tags = ["google","icon"]
      @card = {
        id: "google_icon",
        label: "Google",
        level: "3",
        card_tags: @tags,
        content: {
          type: "GenericImage",
          content: "data:image/png;base64,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"
        }
      }

      post "/cognitive_cards", params: @card.to_json, headers: @headers
    end

    it "return 201 CREATED" do
      expect(response).to have_http_status(:created)
    end

    it "return the created card" do
      card = JSON.parse(response.body)
      expect(card["id"]).to eq(@card[:id])
      expect(card["label"]).to eq(@card[:label])
    end

    it "created a Card" do
      card = Card.find_by_id(@card[:id])
      expect(card).to_not be nil
    end

    it "created a Cognitive Card" do
      card = Card.find_by_id(@card[:id])
      expect(card["type"]).to eq("CognitiveCard")
    end

    it "created the given tags" do
      tag0 = Tag.find_by_tag(@tags[0])
      expect(tag0).to_not be nil

      tag1 = Tag.find_by_tag(@tags[1])
      expect(tag1).to_not be nil
    end

  end

  describe "index" do
    before(:each) do
      @cards = []
      3.times do |i|
        content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/image#{i + 1}.png")))
        @cards << CognitiveCard.create!(id: "cognitive_test_#{i+1}", label: "Cognitive Test #{i+1}", level: 3, card_tag_ids: [], content_id: content.id)
      end

    end

    context "without params" do
      before(:each) do
        get "/cognitive_cards", headers: @headers
      end

      it "return 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "return all Cognitive Cards paginated" do
        headers = response.headers
        expect(headers["Total"].to_i).to eq(CognitiveCard.count)
      end

      it "return ordered by created_at desc" do
        cards = JSON.parse(response.body)
        expect(cards[0]["id"]).to eq(CognitiveCard.reorder(:created_at).last.id)
      end
      
    end

    context "with content params" do
      it "return all cards of the given content" do
        type = "Text"
        get "/cognitive_cards?content=#{type}", headers: @headers

        headers = response.headers

        expect(headers["Total"].to_i).to eq(CognitiveCard.left_outer_joins(:content).group(:id).content_type(type).count().count)
      end

      it "accept an array of types" do
        type1 = "Text"
        type2 = "GenericImage"
        get "/cognitive_cards?content[]=#{type1}&content[]=#{type2}", headers: @headers

        headers = response.headers
        expect(headers["Total"].to_i)
        .to eq(CognitiveCard.left_outer_joins(:content).group(:id).content_type(type1).count().count + CognitiveCard.left_outer_joins(:content).content_type(type2).count())
      end

      it "accept an array of types with superclass Pictogram" do
        type1 = "Text"
        type2 = "Pictogram"
        get "/cognitive_cards?content[]=#{type1}&content[]=#{type2}", headers: @headers

        headers = response.headers
        expect(headers["Total"].to_i)
        .to eq(CognitiveCard.left_outer_joins(:content).group(:id).content_type(type1).count().count + CognitiveCard.left_outer_joins(:content).content_type(type2).count())
      end

      it "accept an array of types with superclass Medium" do
        type1 = "Text"
        type2 = "Medium"

        # Create some fakes, there aren't Video contents in the database
        num_video = 3
        num_video.times do |i|
          content = Video.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_videos/strong1.mp4")))
          @cards << CognitiveCard.create!(id: "cognitive_video_test_#{i+1}", label: "Cognitive Test #{i+1}", level: 3, card_tag_ids: [], content_id: content.id)
        end

        get "/cognitive_cards?content[]=#{type1}&content[]=#{type2}", headers: @headers

        headers = response.headers
        expect(headers["Total"].to_i)
        .to eq(CognitiveCard.left_outer_joins(:content).group(:id).content_type(type1).count().count + num_video)
      end

      it "accept an array of 3 elements" do
        type1 = "Text"
        type2 = "GenericImage"
        type3 = "PersonalImage"

        # Create some fakes, there aren't PersonalImage contents in the database
        num_personal_images = 3
        num_personal_images.times do |i|
          content = PersonalImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/image#{i + 1}.png")))
          @cards << CognitiveCard.create!(id: "cognitive_personal_test_#{i+1}", label: "Cognitive Test #{i+1}", level: 3, card_tag_ids: [], content_id: content.id)
        end

        get "/cognitive_cards?content[]=#{type1}&content[]=#{type2}&content[]=#{type3}", headers: @headers

        headers = response.headers
        expect(headers["Total"].to_i)
        .to eq(CognitiveCard.left_outer_joins(:content).group(:id).content_type(type1).count().count + CognitiveCard.left_outer_joins(:content).content_type(type2).count() + num_personal_images)
      end

    end
  end

end