class Target < ApplicationRecord
  include ParanoidSynchronizable
  # Sub-argument of the cognitive enhancement flow
  # It's a collection of exercixe_trees, executed one after another based
  # on the position value defined in target_layouts

  # after_create :create_relation_for_patients
  after_save :box_update_available_boxes
  after_destroy :deleted_callback

  has_one :box_layout, dependent: :destroy
  has_one :box, through: :box_layout
  has_many :target_layouts, dependent: :destroy
  has_many :exercise_trees, -> { reorder 'target_layouts.position ASC' }, through: :target_layouts
  has_many :available_targets, dependent: :destroy
  has_many :patients, through: :available_targets

  validates :name, presence: true

  delegate :position, to: :box_layout, prefix: false

  scope :base_params, -> {select(:id, :name, :updated_at)}
  scope :published, -> {where(published: true)}
  scope :unpublished, -> {where(published: false)}
  scope :with_exercise_trees_count, -> {left_outer_joins(:exercise_trees).reorder(nil).group(:id).select("count(trees.id) as exercise_trees_count")}

  # Create a relation between the newly created target and all existing Patients
  def create_relation_for_patients
    Patient.all.each do |patient|
      # Override updated_at to exclude the object from synchronization
      self.available_target_for(patient.id).update!(updated_at: DateTime.new(1969, 1, 1, 0, 0, 0).in_time_zone)
    end
  end

  def box_update_available_boxes
    if saved_change_to_attribute?(:published) && self.published
      self.box.update_available_boxes unless self.box.nil?
    end
  end

  def add_exercise_tree( exercise_tree, position = 0)
    TargetLayout.create!(target: self, exercise_tree: exercise_tree, position: position)
    self.box.update_available_boxes unless self.box.nil?
  end

  def first_exercise_tree
    self.exercise_trees.published.first
  end

  # get the exercise_tree that the given patient have to do, the first uncompleted target
  def current_exercise_tree patient
    self.exercise_trees.published.where.not(:id => patient.available_exercise_trees.where(status: [:complete, :unavailable]).select("exercise_tree_id as id")).first
  end

  def completed_exercise_trees patient
    self.exercise_trees.published.where(:id => patient.available_exercise_trees.where(status: [:complete, :unavailable]).select("exercise_tree_id as id"))
  end

  # Get the AvailablTarget for the given patient, create it if it doesn't exist
  def available_target_for patient_id
    if Patient.exists?(patient_id)
      return AvailableTarget.find_or_create_by!(target_id: self.id, patient_id: patient_id)
    else
      return nil
    end
  end

  def conclude_for patient
    available_target = self.available_target_for(patient.id)
    if available_target.update(status: :complete)
      Badge.create!(patient: patient, achievement: "target", target: self)
      self.box.concluded_target_for patient, self
    else
      raise ActiveRecord::Rollback, "Error conclude Target #{self.id}:#{self.name} for #{patient.id}"
    end
  end

  # A patient concluded an ExerciseTree, update the status
  def concluded_exercise_tree_for patient, exercise_tree
    patient_available_exercise_trees = patient.available_exercise_trees.where(exercise_tree_id: self.exercise_trees.published)

    if patient_available_exercise_trees.where(status: [:complete, :unavailable, :unpublished]).count == self.exercise_trees.count
      # All exercise_trees are completed, the Target is completed
      self.conclude_for patient
    else
      # There are available exercise_trees, update the status of the Box
      self.box.concluded_exercise_tree_for patient, self
    end
  end

  def set_as_available_for patient, exercise_tree
    available_target = self.available_target_for(patient.id)
    available_target.update!(status: :available)
    # Delete any previously assigned badges for this target, if they exist
    Badge.where(patient: patient, achievement: "target", target: self).delete_all

    available_box = self.box.available_box_for(patient.id)
    available_box.update_status

    next_target = available_box.box.current_target(patient)
    available_box.set_current(next_target, next_target.first_exercise_tree)

    available_level = self.box.level.available_level_for(patient.id)
    available_level.update!(status: :available)

    Badge.where(patient: patient, achievement: "level", level: self.box.level).delete_all
  end

  def deleted_callback
    self.box_layout.box.deleted_target self
  end

  def deleted_exercise_tree exercise_tree
    Patient.all.each do |patient|
      self.concluded_exercise_tree_for patient, exercise_tree
    end
  end

  # Change the order of the exercise_trees
  def reorder_exercise_trees(order_array)
    # Get all target_layouts, the objects who holds the position field
    target_layouts = self.target_layouts.where(:exercise_tree_id => order_array)

    if order_array.length != target_layouts.count
      return false
    end

    target_layouts.each do |target_layout|
      target_layout.update( position: order_array.index(target_layout.exercise_tree_id)+1)
    end

    return true
  end

  # Update an exercise tree with the given params
  # As we are following the immutable pattern, update is really a soft delete followed by a creation.
  def update_exercise_tree(exercise_tree_id, exercise_tree_params)
    parameters = exercise_tree_params.dup

    # If there are pages I suppose to have here all the infos I need.
    # If pages aren't present, I suppose to have a tree id indicating a tree to be cloned.
    if exercise_tree_params.has_key?(:pages) || exercise_tree_params.has_key?(:presentation_page)
      
      parameters[:id] = SecureRandom.uuid()
      # Prevent the creation of the default_available_exercise_tree
      parameters[:skip_default_available] = true

      begin
        # Create a new exercise tree
        tree_ok = ExerciseTree.create_tree(parameters, false)
        # Archive the old one
        tree = ExerciseTree.find(exercise_tree_id)
        tree.update!(type:"ArchivedTree")
      rescue => exception
        logger.error "Target.update_exercise_tree ERROR Exercise creaton\nexception:#{exception.message}\nparams:#{exercise_tree_params.inspect}"
        return
      end

      if tree_ok.valid?
        # Replace the exercise inside the target
        self.target_layouts.where(exercise_tree_id: exercise_tree_id).update(exercise_tree_id: tree_ok.id)

        # Replace AvailableExerciseTree and AvailableBox
        AvailableExerciseTree.where(exercise_tree_id: exercise_tree_id).update_all(exercise_tree_id: tree_ok.id, updated_at: DateTime.now)
        AvailableBox.where(current_exercise_tree_id: exercise_tree_id).update_all(current_exercise_tree_id: tree_ok.id, current_exercise_tree_name: tree_ok.name, updated_at: DateTime.now)
      end
      return tree_ok
    else
      tree = ExerciseTree.find(exercise_tree_id)
      if tree.update(parameters)
        AvailableBox.where(current_exercise_tree_id: exercise_tree_id).update_all( current_exercise_tree_name: tree.name, updated_at: DateTime.now)
        return tree
      else
        logger.error "Target.update_exercise_tree ERROR Exercise update\nerrors:#{tree.errors.inspect}\nparams:#{exercise_tree_params.inspect}"
        return
      end
    end
  end

end
