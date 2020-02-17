require 'rails_helper'
require 'shared/signin.rb'
require 'shared/tree_utils.rb'

describe Api::V1::CustomCardsController, :type => :request do
  include_context "signin"
  include_context "tree_utils"
  before(:all) do
    signin_researcher
    @patient = Patient.find("patient4")
  end

  context "create" do
    before(:each) do
      @tags = ["google","icon"]
      @card = get_card_hash("google_icon", "Google", 3, @tags, get_content_image_hash, @patient.id)

      post "/custom_cards", params: @card.to_json, headers: @headers
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

    it "created a Custom Card" do
      card = Card.find_by_id(@card[:id])
      expect(card["type"]).to eq("CustomCard")
    end

    it "created the given tags" do
      tag0 = Tag.find_by_tag(@tags[0])
      expect(tag0).to_not be nil

      tag1 = Tag.find_by_tag(@tags[1])
      expect(tag1).to_not be nil
    end

  end

  context "index" do
    before(:each) do
      @cards = []
      5.times do |i|
        content = GenericImage.create!(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/image#{i + 1}.png")))
        @cards << CustomCard.create!(id: "custom_test_#{i+1}", label: "Custom Test #{i+1}", level: 3, patient_id: @patient.id, card_tag_ids: [], content_id: content.id)
      end

      patient_hash = {patient_query: @patient.id}
      get "/custom_cards", params: patient_hash, headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "return all Custom Cards of the patient" do
      cards = JSON.parse(response.body)
      expect(cards.length).to eq(@cards.length)
    end
  end

  describe "update" do

    before(:each) do
      content= Content.create!(id: SecureRandom.uuid(), type: "Text")
      @card = CustomCard.create!(get_card_hash("google_icon", "Google", 3, [], content, @patient.id))
      @card.update(content_id: content.id)

      @new_label = "Big G"
    end

    context "without params" do
      before(:each) do
        update_params = {
          label: @new_label
        }
        put "/custom_cards/#{@card.id}", params: update_params.to_json, headers: @headers
      end

      it "return 201 CREATED" do
        expect(response).to have_http_status(:created)
      end

      it "return the cloned card" do
        card = JSON.parse(response.body)
        expect(card["id"]).to_not be_nil
        expect(card["label"]).to eq(@new_label)
      end

      it "set the cloned card as CustomCard" do
        card = JSON.parse(response.body)
        cloned_card = Card.find_by_id(card["id"])
        expect(cloned_card.type).to eq("CustomCard")
      end

      it "archived the previous Card" do
        card = Card.find_by_id(@card.id)
        expect(card.type).to eq("ArchivedCard")
      end

      it "the cloned card has the same filename" do
        card = JSON.parse(response.body)
        cloned_card = Card.find_by_id(card["id"])
        expect(cloned_card.content.filename).to eq(@card.content.filename)
      end

    end

    context "force_archived=true" do
      before(:each) do
        update_params = {
          label: @new_label
        }
        put "/custom_cards/#{@card.id}?force_archived=true", params: update_params.to_json, headers: @headers
      end

      it "return 201 CREATED" do
        expect(response).to have_http_status(:created)
      end

      it "return the cloned card" do
        card = JSON.parse(response.body)
        expect(card["id"]).to_not be_nil
        expect(card["label"]).to eq(@new_label)
      end

      it "archived the cloned card" do
        card = JSON.parse(response.body)
        cloned_card = Card.find_by_id(card["id"])
        expect(cloned_card.type).to eq("ArchivedCard")
      end

      it "didn't archived the previous Card" do
        card = Card.find_by_id(@card.id)
        expect(card.type).to eq("CustomCard")
      end

      it "the cloned card has the same filename" do
        card = JSON.parse(response.body)
        cloned_card = Card.find_by_id(card["id"])
        expect(cloned_card.content.filename).to eq(@card.content.filename)
      end

    end

    context "force_archived=false" do
      before(:each) do
        update_params = {
          label: @new_label
        }
        put "/custom_cards/#{@card.id}?force_archived=false", params: update_params.to_json, headers: @headers
      end

      it "return 201 CREATED" do
        expect(response).to have_http_status(:created)
      end

      it "return the cloned card" do
        card = JSON.parse(response.body)
        expect(card["id"]).to_not be_nil
        expect(card["label"]).to eq(@new_label)
      end

      it "set the cloned card as CustomCard" do
        card = JSON.parse(response.body)
        cloned_card = Card.find_by_id(card["id"])
        expect(cloned_card.type).to eq("CustomCard")
      end

      it "archived the previous Card" do
        card = Card.find_by_id(@card.id)
        expect(card.type).to eq("ArchivedCard")
      end

      it "the cloned card has the same filename" do
        card = JSON.parse(response.body)
        cloned_card = Card.find_by_id(card["id"])
        expect(cloned_card.content.filename).to eq(@card.content.filename)
      end

    end

    context "content" do
      before(:each) do
        update_params = {
          content:{
            type: "GenericImage",
            mime: "image/jpeg",
            content: get_cat_image_base64
          }
        }
        put "/custom_cards/#{@card.id}", params: update_params.to_json, headers: @headers
      end

      it "return 201 CREATED" do
        expect(response).to have_http_status(:created)
      end

      # it "can update again the card" do
      #   card = JSON.parse(response.body)
      #   expect(card["id"]).to_not be_nil
        
      #   update_params = {
      #     label: "Big G"
      #   }
      #   put "/custom_cards/#{card["id"]}", params: update_params.to_json, headers: @headers
      #   updated_card = JSON.parse(response.body)
      #   puts "response.inspect #{response.inspect}"
      #   puts "response.body.inspect #{response.body.inspect}"
      #   expect(response).to have_http_status(:created)
      #   puts "Content:\n#{Card.find(updated_card["id"]).content.content_url.inspect}"
      # end

      it "the cloned card has a new filename" do
        card = JSON.parse(response.body)
        cloned_card = Card.find_by_id(card["id"])
        expect(cloned_card.content.filename).to_not eq(@card.content.filename)
      end

    end

  end

  describe "clone" do

    before(:each) do
      content= GenericImage.first
      @card = CustomCard.first
      
      put "/custom_cards/#{@card.id}?force_archived=true", params: {}, headers: @headers
    end

    it "return 201 CREATED" do
      expect(response).to have_http_status(:created)
    end

    it "return the cloned card" do
      card = JSON.parse(response.body)
      expect(card["id"]).to_not be_nil
      expect(card["label"]).to eq(@card.label)
    end

    it "archived the cloned card" do
      card = JSON.parse(response.body)
      cloned_card = Card.find_by_id(card["id"])
      expect(cloned_card.type).to eq("ArchivedCard")
    end

    it "didn't archived the previous Card" do
      card = Card.find_by_id(@card.id)
      expect(card.type).to eq("CustomCard")
    end

    it "changed the id of the clone" do
      card = JSON.parse(response.body)
      expect(card["id"]).to_not eq(@card.id)
    end

    it "didn't change the content of the clone" do
      card = JSON.parse(response.body)
      cloned_card = Card.find_by_id(card["id"])
      expect(cloned_card.content_id).to eq(@card.content_id)
    end

    it "didn't change the card params" do
      card = JSON.parse(response.body)
      original_card = JSON.parse(Api::V1::CardSerializer.new(@card).to_json)
      card.keys.each do |key|
        if key != "id" && key != "content" && key != "type"
          expect(card[key]).to eq(original_card[key])
        end
      end
    end

  end

  context "destroy" do
    before(:each) do
      content= Content.create!(id: SecureRandom.uuid(), type: "Text")
      @card = CustomCard.create!(get_card_hash("google_icon", "Google", 3, [], content, @patient.id))
      @card.update(content_id: content.id)

      delete "/custom_cards/#{@card.id}", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "return success true" do
      success = JSON.parse(response.body)
      expect(success["success"]).to be true
    end

    it "didn't destroyed the card" do
      expect(Card.exists?(@card.id)).to be true
    end

    it "archived the card" do
      card = Card.find_by_id(@card[:id])
      expect(card.type).to eq("ArchivedCard")
    end

  end

end