class CardTag < Tag
  validates :tag, uniqueness: true
  
  has_and_belongs_to_many :cards, join_table: "cards_card_tags"
end
