class TargetLayout < ApplicationRecord
  include ParanoidSynchronizable

  belongs_to :target
  belongs_to :exercise_tree

  validates :exercise_tree_id, uniqueness: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }
end
