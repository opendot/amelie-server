class BoxLayout < ApplicationRecord
  include ParanoidSynchronizable
  
  belongs_to :box
  belongs_to :target

  validates :target_id, uniqueness: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  scope :order_position, -> {order(:box_id, :position, :target_id)}
  scope :as_target, -> {select("targets.id AS id", "targets.name AS name", "targets.published AS published", "targets.updated_at AS updated_at", :position)}
  scope :with_exercise_trees_count, -> {left_outer_joins(:target => :exercise_trees).order_position.group(:id).select("count(trees.id) as exercise_trees_count")}
end
