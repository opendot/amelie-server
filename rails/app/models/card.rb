class Card < ApplicationRecord
  include Synchronizable
  
  # The uploader that manages audio files.
  mount_base64_uploader :selection_sound, AudioFileUploader
  
  TYPES = %w(ArchivedCard PresetCard CustomCard CognitiveCard).freeze
  ALL_TYPES = [self.name].concat(TYPES).freeze

  enum selection_action: [:nothing, :play_sound, :synthesize_label]

  has_and_belongs_to_many :card_tags, join_table: "cards_card_tags"
  belongs_to :content, optional: true
  has_many :page_layouts, dependent: :destroy
  has_many :pages, through: :page_layouts

  # Only 5 levels admitted.
  validates :level, inclusion: { in: [1, 2, 3, 4, 5], message: "%{value} #{I18n.t :error_card_level}" }

  # Types are hardcoded in routes, but a validation is always a good thing to have.
  validates :type, inclusion: { in: TYPES, message: "%{value} #{I18n.t :error_card_type}" }

  # Selection actions are defined by constant strings.
  validates :selection_action, inclusion: { in: Card.selection_actions.keys, message: "%{value} #{I18n.t :error_card_selection_action}." }

  # By default cards are public, as they do't belong to a patient. Archived cards and Custom cards are exceptions.
  before_save :ensure_patient_id_is_nil

  # The default order of these record is the creation date
  default_scope { order(:created_at) }

  scope :content_type,  ->  (content_type){ 
    case(content_type)
    when "Medium"
      where(:contents => {type: %w(Audio Video)})
    when "Pictogram"
      where(:contents => {type: %w(DrawingImage GenericImage IconImage PersonalImage)})
    else
      where(:contents => {type: content_type})
    end
  }
  scope :content_longer_than,  ->  (seconds){ where( "`contents`.`duration` > ?", seconds) }
  scope :content_shorter_than,  ->  (seconds){ where( "`contents`.`duration` < ?", seconds) }

  def as_json(options={})
    super(options.merge({:methods => [:type, :tags]}))
  end

  public

  # Returns a deep clone of the current object
  def get_a_clone
    new_card = self.dup
    new_card.card_tags = self.card_tags
    new_card.selection_action = self.selection_action
    unless new_card.selection_sound.url.nil?
      new_card.remote_selection_sound_url = self.selection_sound.url
    else
      new_card.selection_sound = nil
    end
    new_card.id = SecureRandom.uuid()
    new_card.type = "ArchivedCard"
    unless new_card.save
      raise ActiveRecord::Rollback, "Can't save the cloned card: #{new_card.errors.full_messages}"
    end
    return new_card
  end

  # Returns an unsaved clone of the current card. Will point to the original content. Id is not changed.
  def get_an_unsaved_clone
    new_card = {}
    new_card[:label] = self.label
    new_card[:level] = self.level
    new_card[:card_tags] = self.card_tags
    new_card[:content_id] = self.content_id
    new_card[:patient_id] = self.patient_id
    new_card[:selection_action] = self.selection_action
    unless self.selection_sound_url.nil?
      new_card[:remote_selection_sound_url] = self.selection_sound_url
    else
      new_card[:selection_sound] = nil
    end
    new_card[:id] = self.id
    new_card[:type] = "ArchivedCard"
    return new_card
  end

  def self.create(attributes=nil, &block)
    if attributes.is_a? Array
      return super
    end
    tags = attributes[:tags].dup
    attributes.delete(:tags)
    card = super
    unless tags.nil?
      my_tags = []
      tags.each do |tag|
        t = CardTag.create(id: SecureRandom.uuid(), tag: tag)
        my_tags.push(t)
      end
      card.card_tags = my_tags
      card.save!
    end
    return card
  end

  def update(attributes)
    tags = attributes[:tags].dup
    attributes.delete(:tags)
    done = super
    return false unless done
    unless tags.nil?
      my_tags = []
      tags.each do |tag|
        t = CardTag.create(id: SecureRandom.uuid(), tag: tag)
        my_tags.push(t)
      end
      self.card_tags = my_tags
      self.save!
    end
    return true
  end

  private

  # Just set patient_id to nil.
  def ensure_patient_id_is_nil
    self.patient_id = nil
  end

  def tags
    self.card_tags.collect{|tag| tag[:tag]}
  end

  # Write a list of card on a file, used for the Synchronization
  # file: the file object where to write
  # cards_list: the list of cards to write, WARNING limit() and order() are ignored by find_in_batches
  # content_ids: array of ids already added, new contents will be added to the array, can't be nil
  # cards_play_sound_ids: array of ids already added, new cards will be added to the array, can't be nil
  # insert_files_urls: in the content, add the file url
  def self.write_on_file( file, cards_list, content_ids, cards_play_sound_ids, insert_files_urls = false)
    return if file.nil? or cards_list.nil?
    
    # Extract cards with a selection sound
    cards_play_sound_ids.concat(cards_list.play_sound.ids)

    cards_list.find_in_batches do |cards|
      cards_edited = []
      contents = []
      cards.each do |card|
        card_edited = JSON.parse(card.to_json)
        card_edited.delete("selection_sound")
        if insert_files_urls
          if !card.selection_sound.nil? && !card.selection_sound.url.nil?
            card_edited[:remote_selection_sound_url] = card.selection_sound.url
          end
        end
        cards_edited.push(card_edited)
        c = card.content
        unless content_ids.include? c[:id]
          content = c.attributes
          content.delete("content")
          content.delete("content_thumbnail")
          content_ids.push(c[:id])
          if insert_files_urls
            if !c.content.nil? && !c.is_a?(Text) && !c.content.url.nil?
              content[:remote_content_url] = c.content_url
              unless c.content_thumbnail_url.nil?
                content[:remote_content_thumbnail_url] = c.content_thumbnail_url
              end
            end
          end
          contents.push(content)
        end
      end
      file.puts "<Card>"
      file.puts cards_edited.to_json
      file.puts "<Content>"
      file.puts "#{contents.to_json}"
    end
  end
end
