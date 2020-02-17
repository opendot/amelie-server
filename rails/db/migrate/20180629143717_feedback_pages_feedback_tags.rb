class FeedbackPagesFeedbackTags < ActiveRecord::Migration[5.1]
  def change
    create_table :feedback_pages_feedback_tags, id: false do |t|
      t.string :feedback_page_id, index: true
      t.string :feedback_tag_id, index: true
    end
  end
end
