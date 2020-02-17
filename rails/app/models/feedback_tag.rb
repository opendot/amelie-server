class FeedbackTag < Tag
  include Synchronizable
  validates :tag, uniqueness: true
  
  has_and_belongs_to_many :feedback_pages, join_table: "feedback_pages_feedback_tags"
end
  