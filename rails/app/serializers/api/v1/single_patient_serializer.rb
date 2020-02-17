class Api::V1::SinglePatientSerializer < ActiveModel::Serializer
  attributes :id, :name, :surname, :birthdate, :region, :province, :city, :mutation, :disabled, :users

  def users
    if object.users
      ActiveModel::SerializableResource.new(object.users,  each_serializer: Api::V1::SmallUserSerializer)
    end
  end

end

