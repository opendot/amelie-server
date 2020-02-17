class ImmutablePage < Page
  belongs_to :transition_to_page_event, optional:true, foreign_key: 'session_event_id'
  has_many :session_events
end
