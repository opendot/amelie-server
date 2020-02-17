require "rails_helper"
require 'shared/tree_utils.rb'

describe Tree, :type => :model do
  include_context "tree_utils"
  context "without pages" do
    it "have a name" do
      name = "Test tree"
      tree = Tree.new(name: name)
      expect(tree.name).to eq(name)
    end

    it "require a name" do
      tree = Tree.new()
      expect{tree.save!}.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context "get_a_clone" do
    before(:each) do
      # Look for a tree with some pages
      create_tree_with_pages("tree_get_a_clone", "To Clone", 3, Patient.first.id, [CardTag.first.id] )
      @original_tree = Tree.where.not(type: "ExerciseTree", root_page_id: nil).first
      expect(@original_tree.root_page.subtree.length).to be > 1

      @cloned_tree = @original_tree.get_a_clone
    end

    it "return a clone with different id" do
      expect(@cloned_tree.id).to_not eq(@original_tree.id)
    end

    it "return a clone with the same name, patient and user" do
      expect(@cloned_tree.name).to eq(@original_tree.name)
      expect(@cloned_tree.patient_id).to eq(@original_tree.patient_id)
      expect(@cloned_tree.user_id).to eq(@original_tree.user_id)
    end

    it "return a clone with the same number of pages" do
      expect(@cloned_tree.root_page.subtree.length).to eq(@original_tree.root_page.subtree.length)
    end

    it "saved the cloned tree" do
      expect(Tree.exists?(@cloned_tree.id)).to be true
    end

    it "cloned all the pages" do
      tree = Tree.find(@cloned_tree.id)
      # Set an order to pages, since they're returned with a random order
      original_subtree = @original_tree.root_page.subtree.order(:ancestry_depth, :name)
      cloned_subtree = tree.root_page.subtree.order(:ancestry_depth, :name)

      # Check that all pages are cloned
      zip_subtree = original_subtree.zip cloned_subtree
      # zip_subtree = [[original_root_page, cloned_root_page], [original_page_1, cloned_page_1], ...]

      zip_subtree.each do |original_page, cloned_page|
        expect(original_page.id).to_not eq(cloned_page.id)
        expect(original_page.name).to eq(cloned_page.name)
        expect(original_page.background_color).to eq(cloned_page.background_color)
        expect(original_page.cards.count).to eq(cloned_page.cards.count)
      end
    end

  end

end