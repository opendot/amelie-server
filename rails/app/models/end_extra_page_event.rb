class EndExtraPageEvent < SystemEvent
  require_dependency 'session_event'  
 
  skip_callback :save, :before, :ensure_card_id_is_nil
  
end
  