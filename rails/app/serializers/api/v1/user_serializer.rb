class Api::V1::UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :surname, :email, :birthdate, :type, :organization, :role, :description, :disabled, :patients

  def disabled
    object.disabled?
  end

end
