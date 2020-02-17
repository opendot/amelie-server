class AddPatientToInvites < ActiveRecord::Migration[5.1]
  def change
    add_reference :invites, :patient, foreign_key: true, type: :string
  end
end
