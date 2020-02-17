class CreateCardsCardTags < ActiveRecord::Migration[5.1]
  def change
    create_table :cards_card_tags, id: false do |t|
      t.string :card_id, index: true
      t.string :card_tag_id, index: true
    end
  end
end
