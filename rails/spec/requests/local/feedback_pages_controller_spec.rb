require 'rails_helper'
require 'shared/signin.rb'
require 'shared/tree_utils.rb'

describe Api::V1::FeedbackPagesController, :type => :request do
  include_context "signin"
  include_context "tree_utils"
  before(:all) do
    signin_researcher
  end

  context "GET feedback_pages/:id?next_page_id=:next_page_id" do
    before(:each) do
      @feedback_page = FeedbackPage.first
      @next_page_id = "nextId"

      get "/feedback_pages/#{@feedback_page.id}?next_page_id=#{@next_page_id}", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "has the given next_page_id for all cards" do
      page = JSON.parse(response.body)
      expect(page["cards"].length).to be > 0
      page["cards"].each do |card|
        expect(card["next_page_id"]).to eq(@next_page_id)
      end
    end

    it "has the content of the cards" do
      page = JSON.parse(response.body)
      expect(page["cards"].length).to be > 0
      page["cards"].each do |card|
        expect(card["content"]).to_not be_nil
      end
    end

  end

  context "GET feedback_pages/:id?next_page_id=:next_page_id with ArchivedPage" do
    before(:each) do
      @next_page = PresetPage.first
      @feedback_page = FeedbackPage.first.get_a_clone_with_next_page @next_page.id

      get "/feedback_pages/#{@feedback_page.id}?next_page_id=#{@next_page.id}", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "has the given next_page_id for all cards" do
      page = JSON.parse(response.body)
      expect(page["cards"].length).to be > 0
      page["cards"].each do |card|
        expect(card["next_page_id"]).to eq(@next_page.id)
      end
    end

    it "has the content of the cards" do
      page = JSON.parse(response.body)
      expect(page["cards"].length).to be > 0
      page["cards"].each do |card|
        expect(card["content"]).to_not be_nil
      end
    end

  end

  context "PUT feedback_pages/:id" do
    before(:each) do
      @feedback_page = FeedbackPage.negative.first

      @new_card_id = "positive1"
      page = {
        name: @feedback_page.name,
        tags: @feedback_page.feedback_tags.collect { |ft| ft.tag},
        cards: [
          get_page_layout_hash( @new_card_id, correct = nil, next_page_id = nil)
        ],
      }
      expect{
        put "/feedback_pages/#{@feedback_page.id}", params: page.to_json, headers: @headers
      }.to raise_error(ActionController::RoutingError)
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

  end

end