class TimeoutEvent < SystemEvent
  # A timeout happened in the session
  # page_id: the page where the timeout happened
  # card_id: the card related to the timeout, if any
end