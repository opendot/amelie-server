class Api::V1::SessionEventsCollectionSerializer < ActiveModel::Serializer::CollectionSerializer

  def serializer_from_resource(resource, serializer_context_class, options)
    # Use correct serializer based on session event typeplay
    case resource
    when LoadTreeEvent
      return Api::V1::LoadTreeEventSerializer.new(resource, options)
    when PatientChoiceEvent
      return Api::V1::PatientChoiceEventSerializer.new(resource, options)
    when PlayVideoEvent
      return Api::V1::PlayVideoEventSerializer.new(resource, options)
    when ShuffleEvent
      return Api::V1::ShuffleEventSerializer.new(resource, options)
    when TransitionToEndEvent
      return Api::V1::TransitionToEndEventSerializer.new(resource, options)
    when TransitionToPageEvent
      return Api::V1::TransitionToPageEventSerializer.new(resource, options)
    when OperatorEvent
      return Api::V1::OperatorEventSerializer.new(resource, options)
    when SystemEvent
      return Api::V1::SystemEventSerializer.new(resource, options)
    else
      return Api::V1::SessionEventSerializer.new(resource, options)
    end
  end
end
