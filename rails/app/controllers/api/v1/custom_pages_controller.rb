class Api::V1::CustomPagesController < Api::V1::PagesController
  def get_viewable_pages
    if params.has_key?(:page_tag_id)
      pages = Tag.find(params[:page_tag_id]).pages
    else
      pages = Page.all
    end
    if params.has_key?(:type)
      pages = pages.where(type: params[:type])
    end
    if params.has_key?(:patient_id)
      pages = pages.where(patient_id: params[:patient_id])
    end
    return pages
  end
end
