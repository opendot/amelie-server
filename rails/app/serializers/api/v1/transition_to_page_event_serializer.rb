class Api::V1::TransitionToPageEventSerializer < Api::V1::SessionEventSerializer
  attributes :next_page_id
end
