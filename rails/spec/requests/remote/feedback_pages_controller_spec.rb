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
      put "/feedback_pages/#{@feedback_page.id}", params: page.to_json, headers: @headers
    end

    it "return 202 ACCEPTED" do
      expect(response).to have_http_status(:accepted)
    end

    it "updated the cards" do
      page = JSON.parse(response.body)
      expect(page["cards"].length).to eq(1)
      expect(page["cards"][0]["id"]).to eq(@new_card_id)
    end

    it "didn't create a new feedback page" do
      page = JSON.parse(response.body)
      expect(page["id"]).to eq(@feedback_page.id)
    end

  end

  describe "index" do

    context "without params" do
      before(:each) do
        get "/feedback_pages", headers: @headers
      end

      it "return 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "return all feedback pages" do
        expect(response.headers["Total"].to_i).to eq(FeedbackPage.count)
      end

      it "return ordered by created_at desc" do
        pages = JSON.parse(response.body)
        expect(pages[0]["id"]).to eq(FeedbackPage.reorder(:created_at).last.id)
      end
    end

    context "with search params" do
      before(:each) do
        # Create fake pages
        @search = "Hello"

        @no_search_num = 4
        @no_search_num.times do |i|
          create_page( "page_without_search_#{i}", "No name", "FeedbackPage")
        end

        @search_name_num = 3
        @search_name_num.times do |i|
          create_page( "page_with_name_#{i}", "#{@search}_#{i}", "FeedbackPage")
        end

        @search_tag_num = 2
        tag = PageTag.create!(id: SecureRandom.uuid(), tag: @search)
        @search_tag_num.times do |i|
          page = create_page( "page_with_tag_#{i}", "#{@search}_#{i}", "FeedbackPage")
          page.page_tags << tag
          page.save!
        end

        @search_name_and_tag_num = 1
        @search_name_and_tag_num.times do |i|
          page = create_page( "page_with_name_and_tag_#{i}", "#{@search} and tag_#{i}", "FeedbackPage")
          page.page_tags << tag
          page.save!
        end

        get "/feedback_pages?search=#{@search}", headers: @headers
      end

      it "return 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "return only feedback pages with name or tag in the seacrh" do
        expect(response.headers["Total"].to_i).to eq(@search_name_num + @search_tag_num + @search_name_and_tag_num)
      end

    end

  end

end