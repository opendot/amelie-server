class PresentationPage < MutablePage
  include ExtraPage
  # Page used to show a presentation of the tree

  # Use has_one because the foreign_key is in the trees table
  has_one :tree

  has_many :page_layouts, dependent: :destroy, foreign_key: "page_id", after_add: :set_card_not_selectable
end
