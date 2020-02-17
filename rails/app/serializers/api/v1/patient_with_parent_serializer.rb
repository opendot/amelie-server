class Api::V1::PatientWithParentSerializer < ActiveModel::Serializer
  attributes :id, :name, :surname, :birthdate, :region, :province, :city, :mutation, :disabled, :parent

  def parent
    if object.parent
      ActiveModel::SerializableResource.new(object.parent,  each_serializer: Api::V1::SmallUserSerializer)
    end
  end

end

