class Api::V1::SmallUserSerializer < ActiveModel::Serializer
  attributes :id, :name, :surname, :email, :type
end
