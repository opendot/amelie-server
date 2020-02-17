require 'rails_helper'
require 'shared/signin.rb'
require 'shared/tree_utils.rb'

describe Api::V1::PagesController, :type => :request do
  include_context "signin"
  include_context "tree_utils"
  before(:all) do
    signin_researcher
  end

  context "show" do
    before(:each) do
      @page = Page.last

      get "/pages/#{@page.id}", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "contains all cards" do
      page = JSON.parse(response.body)
      expect(page["cards"].length).to be > 0
      page["cards"].each do |card|
        expect(PageLayout.where(page_id: @page.id, card_id: card["id"]).count).to eq(1)
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

end