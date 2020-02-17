class PageTag < Tag
  validates :tag, uniqueness: true
  
  has_and_belongs_to_many :pages, join_table: "pages_page_tags"
end
