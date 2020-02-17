class ExerciseTree < Tree
  # The tree used in a CognitiveSession

  after_create :create_default_available_exercise_tree
  # after_create :create_relation_for_patients
  after_destroy :deleted_callback

  belongs_to :patient, optional: true
  
  has_one :target_layout, dependent: :destroy
  has_one :target, through: :target_layout
  has_many :available_exercise_trees, dependent: :destroy
  has_many :patients, through: :available_exercise_trees
  # has_many :patients, as::ongoing_patients, through: :current_exercise_trees, dependent: :destroy

  delegate :id, :name, :box, :box_layout, to: :target, prefix: true
  delegate :position, to: :target_layout, prefix: :exercise_tree
  delegate :id, :name, :level, to: :target_box, prefix: :box
  delegate :position, to: :target_box_layout, prefix: :target
  delegate :id, :name, :value, to: :box_level, prefix: :level

  CONSECUTIVE_CONCLUSIONS_REQUIRED = 3.freeze

  scope :base_params, -> {select(:id, :name, :root_page_id, :presentation_page_id, :strong_feedback_page_id, :type, :updated_at)}
  scope :published, -> {where(:id => ExerciseTree.joins(:available_exercise_trees).where(:available_exercise_trees => {patient_id: nil}).distinct.where.not(:available_exercise_trees => {status: :unpublished}) )}
  scope :unpublished, -> {where(:id => ExerciseTree.joins(:available_exercise_trees).where(:available_exercise_trees => {patient_id: nil}).distinct.where(:available_exercise_trees => {status: :unpublished}) )}
  scope :with_position, -> {joins(:target_layout).select("target_layouts.position AS position")}
  scope :order_by_level_box_target, -> {includes(:target => [:box => [:level]]).all.reorder("levels.value asc", "box_layouts.position asc", "target_layouts.position asc")}

  attr_accessor :skip_default_available

  # Create a relation between the newly created exercise_tree and all existing Patients
  def create_relation_for_patients
    Patient.all.each do |patient|
      # Override updated_at to exclude the object from synchronization
      self.available_exercise_tree_for(patient.id).update!(updated_at: DateTime.new(1969, 1, 1, 0, 0, 0).in_time_zone)
    end
  end

  def create_default_available_exercise_tree
    return if self.skip_default_available
    AvailableExerciseTree.create!(exercise_tree_id: self.id, patient_id: nil)
  end

  def update_default_available_exercise_tree!(attributes)
    result = self.available_exercise_tree.update!(attributes)

    # Update all dependencies
    new_default = self.available_exercise_tree
    self.available_exercise_trees.where.not(status: :complete).each do |available_exercise_tree|
      available_exercise_tree.update!(status: new_default.status, consecutive_conclusions_required: new_default.consecutive_conclusions_required)
    end

    if attributes.has_key?(:status)
      # Publishing or unpublishing the exercise_tree
      if attributes[:status] != :unpublished
        Box.where( :id => AvailableBox.where(current_target_id: self.target_id, current_exercise_tree_id: nil).select("box_id AS id")).each do |box|
          box.update_available_boxes
        end
      else
        Box.where( :id => AvailableBox.where(current_exercise_tree_id: self.id).select("box_id AS id")).each do |box|
          box.update_available_boxes
        end
      end
    else
      AvailableBox.where(current_exercise_tree_id: self.id).includes(:box).each do |available_box|
        available_box.set_current(self.target, self)
      end
    end

    return result
  end

  # Get the default AvailablExerciseTree
  def available_exercise_tree
    AvailableExerciseTree.where(exercise_tree_id: self.id, patient_id: nil).first
  end

  # Get the AvailablExerciseTree for the given patient, create it if it doesn't exist
  def available_exercise_tree_for patient_id
    if Patient.exists?(patient_id)
      patient_available_exercise_tree = AvailableExerciseTree.where(exercise_tree_id: self.id, patient_id: patient_id).first
      if patient_available_exercise_tree.nil?
        # Create with default values
        available_exercise_tree = self.available_exercise_tree
        patient_available_exercise_tree = AvailableExerciseTree.create(exercise_tree_id: self.id, patient_id: patient_id)
        patient_available_exercise_tree.status = available_exercise_tree.status
        patient_available_exercise_tree.consecutive_conclusions_required = available_exercise_tree.consecutive_conclusions_required
        patient_available_exercise_tree.save!
      end
      return patient_available_exercise_tree
    else
      return nil
    end
  end

  # The given patient has concluded the current ExerciseTree
  def conclude_for patient
    available_exercise_tree = self.available_exercise_tree_for(patient.id)
    raise "Can't conclude ExerciseTree for not existing Patient" if available_exercise_tree.nil?
    available_exercise_tree.update!(status: :complete)
    self.target.concluded_exercise_tree_for patient, self
  end

  def deleted_callback
    self.target_layout.target.deleted_exercise_tree self
  end

  # The given patient completed the exercise, the result is given by success
  def completed_by(patient, success, force = false, bypass_completion_checks = false)
    raise I18n.t :error_invalid_parameters if patient.nil? || success.nil?
    available_exercise_tree = self.available_exercise_tree_for(patient.id)
    raise I18n.t :error_invalid_parameters if available_exercise_tree.nil?
    if success
      available_exercise_tree.increment_count

      # The exercise is concluded if:
      # - the patient completed the exercise N consecutives times
      # - the patient completed the exercise at his first attempt
      if bypass_completion_checks || available_exercise_tree.consecutive_conclusions_passed? || available_exercise_tree.total_attempts_count == 1
        self.conclude_for(patient)
      end
    else
      available_exercise_tree.reset_count
    end

    if force
      available_exercise_tree.update!(force_completed: true)
    end

    self.available_box_for(patient.id).update!(last_completed_exercise_tree_at: DateTime.now.in_time_zone)
  end

  def set_as_available_for(patient)
    raise I18n.t :error_invalid_parameters if patient.nil?
    available_exercise_tree = self.available_exercise_tree_for(patient.id)
    raise I18n.t :error_invalid_parameters if available_exercise_tree.nil?

    available_exercise_tree.update!(status: :available)
    available_exercise_tree.decrement_count

    self.target.set_as_available_for patient, self
  end

  # Delete the exercise, that is set it as archived
  def archive
    # Destroy links with target and patients
    self.target_layout.destroy
    self.available_exercise_trees.destroy_all

    self.deleted_callback
  end

  def self.create_tree(params, archived = false)
    # There is no patient inan ExerciseTree

    if Tree.exists?(id: params[:id])
      logger.error "Tree already exists"
      raise ActiveRecord::Rollback, ["#{I18n.t :error_tree_already_exists}."]
    end

    # Acquire parameters, but don't care for pages. Pages will be handled later
    parameters = params.deep_dup
    parameters.delete(:pages)
    parameters.delete(:favourite)
    parameters.delete(:presentation_page)
    
    # Save nothing if something goes wrong
    ExerciseTree.transaction do
      tree = ExerciseTree.new(parameters)
      if archived
        tree.type = ArchivedTree
      else
        tree.type = ExerciseTree
      end

      # Now it's time to take care of pages
      # parameters = params[:pages].deep_dup

      parameters  = params.deep_dup
      
      card_ids = []
      page_layouts = []
      pages = []
      # Don't clone cards any more.
      # cards_source_ids = {}
      # cards_modified_ids = []
      # Get pages and cards. Pages are definitive, cards need to be copied.
      parameters[:pages].each do |page|
        if page[:level] == 0
          tree[:root_page_id] = page[:id]
        end
        page[:cards].each do |card|
          # Don't clone cards any more.
          # new_card_id = SecureRandom.uuid()
          # cards_source_ids[new_card_id] = card[:id]
          # cards_modified_ids.push(new_card_id)
          card_ids.push(card[:id])
          layout = create_page_layout_hash(page, card)
          layout[:correct] = card[:correct]
          page_layouts.push(layout)
        end

        new_page = create_page_hash(page, "ArchivedCardPage", parameters[:patient_id])
        pages.push(new_page)
      end

      if tree[:root_page_id].nil?
        @errors = [I18n.t("errors.trees.missing_root_page")]
        raise ActiveRecord::Rollback, @errors
      end

      # Now I can change all the pages ids.
      change_page_ids( tree, pages, card_ids, page_layouts )

      # Here I reorder pages to be sure that parents are created before their childrens
      pages = reorder_pages(pages)


      # Create pages
      ArchivedCardPage.create!(pages)

      # Create page layouts
      CognitivePageLayout.create!(page_layouts)

      create_presentation_page(tree, params[:presentation_page])

      if tree.save
        # Find the created tree, to have an instance with the correct type (Exercisetree or ArchivedTree)
        return Tree.find(tree.id)
      else
        @errors = tree.errors.full_messages
        logger.error "Error: can't save ExerciseTree: #{tree.errors.full_messages}"
        raise ActiveRecord::Rollback, "#{I18n.t :error_cant_create_tree}"
      end
    end

    # If this code gets executed it means something went wrong with the transaction.
    logger.error "Error: #{@errors.inspect}"
    raise ActiveRecord::ActiveRecordError, @errors
  end

  def available_box_for patient_id
    self.target_box.available_box_for patient_id
  end

  def available_target_for patient_id
    self.target.available_target_for patient_id
  end

  def consecutive_times_left_for patient_id
    available_exercise_tree = self.available_exercise_tree_for patient_id
    raise "consecutive_times_left_for Invalid patient_id #{patient_id}" if available_exercise_tree.nil?

    return available_exercise_tree.consecutive_conclusions_required - available_exercise_tree.conclusions_count
  end
  
  def unpublished?
    self.available_exercise_tree.unpublished?
  end

  def set_published(published)
    # The published value is defined in the AvailableExerciseTree with patient_id: nil
    currently_published = !self.unpublished?
    if published && !currently_published
      self.update_default_available_exercise_tree!(status: :available)
    elsif !published && currently_published
      self.update_default_available_exercise_tree!(status: :unpublished)
    end
  end

end
