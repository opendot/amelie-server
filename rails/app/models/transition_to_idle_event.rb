class TransitionToIdleEvent < TransitionToPageEvent
  require_dependency 'transition_to_page_event'  

  skip_callback :create, :after, :broadcast_transition_message
end
