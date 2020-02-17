require 'rails_helper'

RSpec.describe Card, type: :model do

  context "to_json" do
    before(:each) do
      @card_json = Card.first.to_json
    end

    it "has tags" do
      expect(JSON.parse(@card_json)).to have_key("tags")
    end
  end

  context "write_on_file" do

    before(:each) do
      # Use StringIO to check what is written on file
      @file = StringIO.new

      # Select some cards
      @cards = Card.where(:id => PageLayout.where(:page_id => ExerciseTree.first.root_page.subtree.select(:id)).select(:card_id))
      
      @content_ids = []
      @cards_play_sound_ids = []

      Card.write_on_file(@file, @cards, @content_ids, @cards_play_sound_ids, false)
    end

    it "added content ids to the array" do
      @cards.each do |card|
        expect(@content_ids.include?(card.content_id)).to be true
      end
    end

    it "added tags list to the card" do
      what = nil
      @file.string.lines.each do |line|
        line = line.strip

        # Ignore comments
        next if line.start_with?('#')
        # Ignore empty lines
        next if line.empty?
        # If starts with "<" and ends with ">" is a class type. Just need to set the type we are working with.
        if line.start_with?('<') && line.ends_with?('>')
          what = line[1..-2]
          next
        end

        case what
        when "Card"
          cards = JSON.parse(line)
          cards.each do |card|
            expect(card).to have_key("tags")
          end
        end
      end
    end

  end
end
