class CognitivePageLayout < PageLayout
  # PageLayout used for ExerciseTree in CognitiveSession
  # it also possess the attribute correct to identify if the chosen card
  # is the correct one

  validates_inclusion_of :correct, :in => [true, false]
end