class ArchivedCard < ImmutableCard
  require_dependency 'card'
  
  belongs_to :patient_choice_event, optional: true, foreign_key: 'session_event_id'
  belongs_to :archived_card_page, optional: true, foreign_key: 'page_id'

  # This type of card is an exception ad is allowed to be linked to a patient, belong to a page and have position and scale.
  skip_callback :save, :before, :ensure_patient_id_is_nil

end
