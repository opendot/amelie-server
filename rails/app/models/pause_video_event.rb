class PauseVideoEvent < SystemEvent
  require_dependency 'session_event'  

  skip_callback :save, :before, :ensure_card_id_is_nil

  has_one :archived_card
end
