class ShuffleEvent < OperatorEvent
  require_dependency 'session_event'  
  
  # Shuffle event uses the next_page_id field to store a page linked to a new PageLayout with the updated
  # cards positions.
  skip_callback :save, :before, :ensure_next_page_id_is_nil

  # The next_page is a page never visible to the user, made to store the position in which shuffle put
  # the cards.
  belongs_to :next_page, dependent: :destroy, foreign_key: 'next_page_id', class_name: 'Page'
end
