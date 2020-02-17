class Api::V1::FeedbackPageSerializer < Api::V1::PageSerializer
  has_many :feedback_tags, serializer: Api::V1::TagSerializer
end
