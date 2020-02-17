class UserTree < ApplicationRecord
  include Synchronizable

  default_scope { order(:created_at) }
  belongs_to :user
  belongs_to :tree

  # Create many object with a single query
  # WARNING the objects created skip validation, this must be used only for the Synchronization
  def self.create_from_array( hash_array )
    return if hash_array.empty?
    values = hash_array.map do |a|
      "('#{a[:id]}','#{a[:user_id]}','#{a[:tree_id]}',#{a[:favourite] ? 1 : 0},'#{DateTime.parse(a[:created_at]).utc.to_formatted_s(:db)}','#{(a[:updated_at].nil? ? DateTime.now : DateTime.parse(a[:updated_at])).utc.to_formatted_s(:db)}')"
    end
    values = values.join(",")
    ActiveRecord::Base.connection.execute(
      "INSERT INTO #{self.table_name} #{self.keys} VALUES #{values}"
    )
  end

end
