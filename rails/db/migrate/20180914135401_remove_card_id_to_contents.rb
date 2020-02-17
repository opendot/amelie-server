class RemoveCardIdToContents < ActiveRecord::Migration[5.1]

  # Define the models that I use, this way if the models are edited
  # I'm sure that the code inside up and down doesn't break
  # class Card < ApplicationRecord
  #   has_one :content
  #   validates :type, inclusion: { in: %w(ArchivedCard PresetCard CustomCard CognitiveCard), message: "%{value} #{I18n.t :error_card_type}" }
  # end
  # class Content < ApplicationRecord
  #   belongs_to :card, optional: true
  #   validates :type, inclusion: { in: %w(PersonalImage GenericImage DrawingImage IconImage Medium Text Link Video), message: "%{value} #{I18n.t :error_content_type}" }
  # end

  def self.up
    # Fix cards that doesn't have a content_id
    # Card.where(content_id: nil).each do |card|
    #   content = card.content
    #   unless content.nil?
    #     card.update(content_id: content.card_id)
    #   end
    # end

    remove_column :contents, :card_id, :string
  end

  def self.down
    add_column :contents, :card_id, :string

    # Assign the card_id to the content
    # Content.all.each do |content|
    #   card = Card.where(content_id: content.id).first
    #   unless card.nil?
    #     content.update(card_id: card.id)
    #   end
    # end
  end

end
