class Tag < ApplicationRecord
  include Synchronizable
  validates :type, inclusion: { in: %w(CardTag PageTag FeedbackTag), message: "%{value} #{I18n.t :error_tag_type}" }
  validates :tag, presence: true

  def self.create(attributes = nil, &block)
    if attributes.is_a? Array
      return super
    end
    type_to_search = self
    type_to_search = attributes[:type] unless attributes[:type].nil?
    existent = Tag.find_by(tag: attributes[:tag], type: type_to_search)
    if existent.nil?
      return super
    end
    return existent
  end

  def as_json(options={})
    super(options.merge({:methods => :type}))
  end
end
