require 'rails_helper'
require 'shared/signin.rb'
require 'shared/tree_utils.rb'

describe Api::V1::CustomTreesController, :type => :request do
    include_context "signin"
    include_context "tree_utils"
    before(:all) do
        signin_researcher
    end

    context "basic CRUD" do
        it "create" do
            patient = Patient.first
            id = SecureRandom.uuid()
            page_id = SecureRandom.uuid()

            tree = {
                id: id, name: "My New Tree", patient_id: patient.id,
                pages: [
                    {
                        id: page_id,
                        name: "Create Tree Root Page",
                        level: 0,
                        page_tags: [],
                        cards: [
                            {
                                id: "card5",
                                x_pos: 0.073,
                                y_pos: 0.013,
                                scale: 1,
                            }
                        ],
                        background_color: "black",
                    },
                ],
            }

            post "/custom_trees", params: tree.to_json, headers: @headers

            expect(response).to have_http_status(:created)

            created_tree = JSON.parse(response.body)
            expect(created_tree["id"]).to eq(id)
            # Server will change the id of the pages
            expect(created_tree["pages"][0]["id"]).not_to eq(page_id)
        end

        it "update" do
            # The update it's actually a soft delete followed by a create

            # First create a tree
            patient = Patient.first
            id = SecureRandom.uuid()
            page_id = SecureRandom.uuid()

            tree = {
                id: id, name: "My New Tree", patient_id: patient.id,
                pages: [
                    {
                        id: page_id,
                        name: "Create Tree Root Page",
                        level: 0,
                        page_tags: [],
                        cards: [
                            {
                                id: "card5",
                                x_pos: 0.073,
                                y_pos: 0.013,
                                scale: 1,
                            }
                        ],
                        background_color: "black",
                    },
                ],
            }

            post "/custom_trees", params: tree.to_json, headers: @headers
            expect(response).to have_http_status(:created)
            created_tree = JSON.parse(response.body)

            # Update the newly created tree
            created_tree["favourite"] = true;

            put "/custom_trees/#{created_tree["id"]}", params: created_tree.to_json, headers: @headers
            expect(response).to have_http_status(:accepted)

            # The updated tree it's actually a new created tree

            updated_tree = JSON.parse(response.body)
            
            expect(updated_tree["id"]).not_to eq(created_tree["id"])
            expect(updated_tree["favourite"]).to eq(true)
            expect(updated_tree["pages"][0]["id"]).not_to eq(created_tree["pages"][0]["id"])
        end
    end

    context "create with Presentation Page" do
        before(:each) do
            @patient = Patient.first
            @id = SecureRandom.uuid()
            @page_id = SecureRandom.uuid()
            @presentation_page_id = SecureRandom.uuid()
            tree = {
                id: @id, name: "My New Tree", patient_id: @patient.id,
                pages: [
                    {
                        id: @page_id,
                        name: "Create Tree Root Page",
                        level: 0,
                        page_tags: [],
                        cards: [
                            {
                                id: "card5",
                                x_pos: 0.073,
                                y_pos: 0.013,
                                scale: 1,
                            }
                        ],
                        background_color: "black",
                    },
                ],
                presentation_page: {
                    id: @presentation_page_id,
                    name: "Test Presentation Page",
                    cards: [
                        {
                            id: "card4",
                            x_pos: 0.1,
                            y_pos: 0.1,
                            scale: 1
                        }
                    ],
                    page_tags: []
                }
            }

            post "/custom_trees", params: tree.to_json, headers: @headers
        end

        it "respond 201 CREATED" do
            expect(response).to have_http_status(:created)
        end

        it "return the created tree" do
            created_tree = JSON.parse(response.body)
            expect(created_tree["id"]).to eq(@id)
        end

        it "created the Presentation Page" do
            expect(PresentationPage.exists?(@presentation_page_id)).to be true
        end

        it "created te tree with the presentation page" do
            created_tree = JSON.parse(response.body)
            tree = Tree.find(created_tree["id"])
            expect(tree.presentation_page_id).to eq(@presentation_page_id)
        end
    end

    context "create with not selectable pages" do
        before(:each) do
            @patient = Patient.first
            @id = SecureRandom.uuid()
            @page_id = SecureRandom.uuid()
            @cards_array = @patient.custom_cards.limit(3).to_a
            tree = {
                id: @id, name: "My New Tree", patient_id: @patient.id,
                pages: [
                    get_page_hash_with_cards( @page_id, [
                        get_page_layout_hash(@cards_array[0].id, false),
                        get_page_layout_hash(@cards_array[1].id),
                        get_page_layout_hash(@cards_array[2].id),
                    ], 0),
                ],
            }

            tree[:pages][0][:cards][0][:selectable] = true
            tree[:pages][0][:cards][1][:selectable] = false

            post "/custom_trees", params: tree.to_json, headers: @headers
        end

        it "respond 201 CREATED" do
            expect(response).to have_http_status(:created)
        end

        it "correctly returns the pages selectable" do
            created_tree = JSON.parse(response.body)
            created_tree["pages"][0]["cards"] do |card|
                if card["id"] == @cards_array[0].id
                    expect(card["selectable"]).to be true
                end
            end
        end

        it "correctly returns the pages unselectable" do
            created_tree = JSON.parse(response.body)
            created_tree["pages"][0]["cards"] do |card|
                if card["id"] == @cards_array[1].id
                    expect(card["selectable"]).to be false
                end
            end
        end

        it "correctly returns the pages with undefined selectable" do
            created_tree = JSON.parse(response.body)
            created_tree["pages"][0]["cards"] do |card|
                if card["id"] == @cards_array[2].id
                    expect(card["selectable"]).to be true
                end
            end
        end

    end

    context "update without pages" do
        before(:each) do
            @patient = Patient.first
            @id = SecureRandom.uuid()
            @tree = create_tree(@id, "to_be_updated", @patient.id)
            @new_name = "no_pages_updated"

            tree = {
                name: @new_name,
            }
            put "/custom_trees/#{@tree.id}", params: tree.to_json, headers: @headers
        end

        it "respond 202 ACCEPTED" do
            expect(response).to have_http_status(:accepted)
        end

        it "return the updated tree" do
            tree = JSON.parse(response.body)
            expect(tree["name"]).to eq(@new_name)
        end

        it "didn't created a new tree" do
            tree = JSON.parse(response.body)
            expect(tree["id"]).to eq(@tree.id)
        end

        it "return a custom tree" do
            tree = Tree.find(JSON.parse(response.body)["id"])
            expect(tree.type).to eq("CustomTree")
        end

    end

    context "update with pages" do
        before(:each) do
            @patient = Patient.first
            @id = SecureRandom.uuid()
            @tree = create_tree(@id, "pages_updated", @patient.id)
            @cards_array = @patient.custom_cards.limit(3).to_a
            
            # Since the update create a new tree, I have to send the other params like in a CREATE
            tree = {
                name: @tree.name,
                patient_id: @patient.id,
                pages: [
                    get_page_hash_with_cards( "new_page_1", [
                        get_page_layout_hash(@cards_array[0].id, false, "new_page_2"),
                        get_page_layout_hash(@cards_array[1].id),
                    ], 0),
                    get_page_hash_with_cards( "new_page_2", [
                        get_page_layout_hash(@cards_array[2].id, false, "new_page_3"),
                        get_page_layout_hash(@cards_array[0].id),
                    ], 1),
                    get_page_hash_with_cards( "new_page_3", [
                        get_page_layout_hash(@cards_array[1].id),
                        get_page_layout_hash(@cards_array[2].id),
                    ], 2),
                ],
            }
            put "/custom_trees/#{@tree.id}", params: tree.to_json, headers: @headers
        end

        it "respond 202 ACCEPTED" do
            expect(response).to have_http_status(:accepted)
        end

        it "return the updated tree" do
            tree = JSON.parse(response.body)
            expect(tree["pages"].count).to eq(3)
        end

        it "created a new tree" do
            tree = JSON.parse(response.body)
            expect(tree["id"]).to_not eq(@tree.id)
        end

        it "return a custom tree" do
            tree = Tree.find(JSON.parse(response.body)["id"])
            expect(tree.type).to eq("CustomTree")
        end

        it "archived the previous tree" do
            tree = Tree.find(@id)
            expect(tree.type).to eq("ArchivedTree")
        end

        it "has the correct number of pages" do
            tree = Tree.find(JSON.parse(response.body)["id"])
            expect(tree.root_page.subtree.count).to eq(3)
        end
    end

    context "delete" do
        before(:each) do
            @patient = Patient.first
            @id = SecureRandom.uuid()
            @tree = create_tree(@id, "deleted", @patient.id)

            delete "/custom_trees/#{@tree.id}", headers: @headers
        end

        it "return 200 OK" do
            expect(response).to have_http_status(:ok)
        end
    
        it "return success true" do
            success = JSON.parse(response.body)
            expect(success["success"]).to be true
        end
    
        it "didn't destroyed the tree" do
            expect(Tree.exists?(@id)).to be true
        end
    
        it "archived the tree" do
            tree = Tree.find_by_id(@id)
            expect(tree.type).to eq("ArchivedTree")
        end

    end

end
