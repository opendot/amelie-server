require 'rails_helper'
require 'shared/signin.rb'
require 'shared/tree_utils.rb'

describe Api::V1::CustomPagesController, :type => :request do
  include_context "signin"
  include_context "tree_utils"
  before(:all) do
    signin_researcher
  end

  context "show" do
    before(:each) do
      @patient = Patient.first
      @custom_page = @patient.custom_pages.first

      get "/custom_pages/#{@custom_page.id}", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "has the content of the cards" do
      page = JSON.parse(response.body)
      expect(page["cards"].length).to be >= 0
      page["cards"].each do |card|
        expect(card["content"]).to_not be_nil
      end
    end

  end

  context "update" do
    before(:each) do
      @patient = Patient.first
      create_page( SecureRandom.uuid(), "Immutable Update", "CustomPage", @patient.id)
      @custom_page = @patient.custom_pages.last

      @new_card_id = PresetCard.first.id
      page = {
        name: @custom_page.name,
        tags: @custom_page.page_tags.collect { |pt| pt.tag},
        cards: [
          get_page_layout_hash( @new_card_id, correct = nil, next_page_id = nil)
        ],
      }
      put "/custom_pages/#{@custom_page.id}", params: page.to_json, headers: @headers
    end

    it "return 202 ACCEPTED" do
      expect(response).to have_http_status(:accepted)
    end

    it "updated the cards" do
      page = JSON.parse(response.body)
      expect(page["cards"][0]["id"]).to eq(@new_card_id)
    end

    it "created a new custom page" do
      page = JSON.parse(response.body)
      expect(page["id"]).to_not eq(@custom_page.id)
    end

    it "archived the previous custom page" do
      page = Page.find(@custom_page.id)
      expect(page.type).to eq("ArchivedCardPage")
    end

  end

end