require 'rails_helper'
require "cancan/matchers"

RSpec.describe GuestUser, type: :model do

  context "abilities" do
    before(:each) do
      @guest_user = GuestUser.first
      @ability = Ability.new(@guest_user)
    end

    it "can't manage Synchronizaion" do
      expect(@ability).to_not be_able_to(:manage, Synchronization)
    end

    # it "can manage Cards" do
    #   expect(@ability).to be_able_to(:manage, Card)
    # end

    # it "can manage CustomCards" do
    #   expect(@ability).to be_able_to(:manage, CustomCard)
    # end

    # it "can manage PresetCards" do
    #   expect(@ability).to be_able_to(:manage, PresetCard)
    # end

    it "can't manage CognitiveCards" do
      expect(@ability).to_not be_able_to(:manage, CognitiveCard)
    end

  end

end