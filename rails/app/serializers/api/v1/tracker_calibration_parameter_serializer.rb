class Api::V1::TrackerCalibrationParameterSerializer < ActiveModel::Serializer
  attributes :id, :setting, :fixing_radius, :fixing_time_ms, :transition_matrix, :trained_fixation_time, :type
end
