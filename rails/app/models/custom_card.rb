class CustomCard < MutableCard
  require_dependency 'card'
  belongs_to :patient

  # This type of card is an exception ad is allowed to be linked to a patient
  skip_callback :save, :before, :ensure_patient_id_is_nil

end
