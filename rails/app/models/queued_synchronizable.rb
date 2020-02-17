class QueuedSynchronizable < ApplicationRecord
  # Temporary object that represent a Synchronizable object that is meant to be synchonrized,
  # but for any reason it's still not.
  # If this list is not empty for the patient, the user will be forced to make a Synchronization
  # synchronizable_id:    id of the synchronizable object
  # synchronizable_type:  class of the synchronizable object
  # patient_id:           id of the patient related to the synch

  belongs_to :patient, optional: false
  belongs_to :user, optional: false

  validates :synchronizable_id, presence: true
  validates :synchronizable_type, presence: true

  scope :for_patient,  ->  (patient_id){ where(patient_id: patient_id) }
  scope :select_ids,  ->  { select("synchronizable_id AS id") }

  def synchronizable
    self.synchronizable_type.constantize.find(self.synchronizable_id)
  end

  def self.create_for(patient_id, user_id, synchronizable)
    QueuedSynchronizable.create(
      patient_id: patient_id,
      user_id: user_id,
      synchronizable_id: synchronizable.id,
      synchronizable_type: synchronizable.class.name,
    )
  end

  def self.create_for!(patient_id, user_id, synchronizable)
    QueuedSynchronizable.create!(
      patient_id: patient_id,
      user_id: user_id,
      synchronizable_id: synchronizable.id,
      synchronizable_type: synchronizable.class.name,
    )
  end

  def self.create_from_synchronizable_array(patient_id, user_id, synchronizables)
    synchronizables.select(
      synchronizables.column_names.include?("type") ? [:id, :type] : [:id]
    ).find_in_batches(batch_size: 10) do |group|
      group.each do |s|
        QueuedSynchronizable.create_for!(patient_id, user_id, s)
      end
    end
  end

  def self.destroy_for(patient_id, user_id, synchronizable)
    QueuedSynchronizable.where(
      patient_id: patient_id,
      user_id: user_id,
      synchronizable_id: synchronizable.id,
      synchronizable_type: synchronizable.class.name,
    ).destroy_all
  end

  def self.destroy_for(patient_id, synchronizable)
    QueuedSynchronizable.where(
      patient_id: patient_id,
      synchronizable_id: synchronizable.id,
      synchronizable_type: synchronizable.class.name,
    ).destroy_all
  end

end
