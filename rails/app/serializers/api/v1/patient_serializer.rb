class Api::V1::PatientSerializer < ActiveModel::Serializer
  attributes :id, :name, :surname, :birthdate, :region, :province, :city, :mutation, :disabled
end
