class PageLayout < ApplicationRecord
  include Synchronizable

  before_create :generate_id
  before_save :default_values

  belongs_to :page
  belongs_to :card

  default_scope { order(:created_at) }

  private

  def generate_id
    if self.id.blank?
      self.id = SecureRandom.uuid()
    end
  end

  def default_values
    self.selectable = PageLayout.column_defaults["selectable"] if self.selectable.nil?
  end

  # Create many object with a single query
  # WARNING the objects created skip validation, this must be used only for the Synchronization
  def self.create_from_array( hash_array )
    return if hash_array.empty?
    values = hash_array.map do |a|
      "('#{a[:id]}','#{a[:page_id]}','#{a[:card_id]}',#{a[:x_pos] || "NULL"},#{a[:y_pos] || "NULL"},#{a[:scale] || "NULL"},#{a[:next_page_id] ? "'#{a[:next_page_id]}'" : "NULL"},#{a[:hidden_link] ? 1 : 0},'#{DateTime.parse(a[:created_at]).utc.to_formatted_s(:db)}','#{(a[:updated_at].nil? ? DateTime.now : DateTime.parse(a[:updated_at])).utc.to_formatted_s(:db) }',#{a[:type] ? "'#{a[:type]}'" : "NULL"},#{a[:correct].nil? ? "NULL" : (a[:correct] ? 1 : 0)},#{a[:selectable] ? 1 : 0})"
    end
    values = values.join(",")
    ActiveRecord::Base.connection.execute(
      "INSERT INTO #{self.table_name} #{self.keys} VALUES #{values}"
    )
  end

end
