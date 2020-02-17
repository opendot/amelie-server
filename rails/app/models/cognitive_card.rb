class CognitiveCard < MutableCard
  # A Card used only for objects related to CognitiveSession, like ExerciseTree

  has_many :cognitive_page_layouts, foreign_key: "card_id", dependent: :destroy

  default_scope { reorder(created_at: :desc) }
end
