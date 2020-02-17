class Api::V1::CardsController < ApplicationController

  def index
    cards = get_viewable_cards
    if params.has_key?(:tag_query)
      cards = filter_by_query(cards, params[:tag_query])
      cards = Card.where(id: cards.ids)
    end
    if params.has_key?(:patient_query)
      cards = cards.where(patient_id: params[:patient_query]).or(cards.where(type: "PresetCard"))
    else
      cards = cards.where(type: "PresetCard")
    end
    if params.has_key?(:content)
      cards = cards.left_outer_joins(:content)
      cards = filter_by_content_type(cards)
    end
    cards = filter_by_content_duration(cards)
    cards = order_by_default_level(cards)
    cards = paginate cards.reorder('')
    cards = cards.includes(:content, :card_tags)
    render json: cards, each_serializer: Api::V1::CardSerializer, status: :ok
  end

  def show
    card = nil
    if params.has_key?(:type)
      card = params[:type].to_s.constantize.includes(:content, :card_tags).find(params[:id])
    else
      card = Card.includes(:content, :card_tags).find(params[:id])
    end
    render json: card, serializer: Api::V1::CardSerializer, status: :ok
  end

  def create
    if Card.exists?(card_params[:id])
      render json: {errors: ["#{I18n.t :error_card_already_exists}"]}, status: :unprocessable_entity
      return
    end
    Card.transaction do
      parameters = card_params
      content = create_card_content(parameters)
      parameters = card_params
      parameters.delete(:content)
      parameters.delete(:card_tags)
      parameters.delete(:force_archived)
      parameters = process_audio_file(parameters)
      card = Card.new(parameters)
      card.content = content
      card.content_id = content[:id]
      set_card_tags_and_render(card)
    end
  end

  def update
    card = nil
    original_card = Card.includes(:content, :card_tags).find(params[:id])
    Card.transaction do
      card = create_clone_hash(original_card, card_params, "CustomCard", true)
      return if card.nil?
      card = Card.create(card)
      if original_card[:type] == "CustomCard" && !(params[:force_archived] == "true")
        original_card.update(type: "ArchivedCard")
      end
      parameters = card_params
      # Create the content. Will be nil if a new content has not been supplied.
      content = create_card_content(parameters)
      if content.nil?
        # There wasn't a new content. Clone the old one.
        content = clone_previous_content(original_card, card)
        return if content.nil?
      end
      parameters = process_audio_file(parameters)
      parameters.delete(:content)
      parameters.delete(:id)
      parameters.delete(:force_archived)
      if params[:force_archived] == "true"
        parameters.delete(:type)
      end
      parameters[:content_id] = content[:id]
      if params.has_key?(:card_tags)
        parameters[:card_tags] = []
      end
      card.update_attributes(parameters)
      card.content = content
      set_card_tags_and_render(card)
    end
  end

  def create_form_data
    # Extract the card parameters
    card_hash = card_format_data

    if Card.exists?(card_hash[:id])
      render json: {errors: ["#{I18n.t :error_card_already_exists}"]}, status: :unprocessable_entity
      return
    end

    Card.transaction do
      parameters = add_card_permit(card_hash)
      content = create_card_content(parameters)
      parameters = add_card_permit(card_hash)
      parameters.delete(:content)
      parameters.delete(:card_tags)
      parameters.delete(:force_archived)
      parameters = process_audio_file(parameters)
      card = Card.new(parameters)
      card.content = content
      card.content_id = content[:id]
      set_card_tags_and_render(card, card_hash[:card_tags])
    end
  end

  def update_form_data
    card_hash = card_format_data
    card_hash[:force_archived] = params[:force_archived]
    card = nil
    original_card = Card.includes(:content, :card_tags).find(card_hash[:id])
    Card.transaction do
      card = create_clone_hash(original_card, card_hash, "CustomCard", true)
      return if card.nil?
      card = Card.create(card)
      if original_card[:type] == "CustomCard" && !(card_hash[:force_archived] == "true")
        original_card.update(type: "ArchivedCard")
      end
      parameters = add_card_permit(card_hash)
      # Create the content. Will be nil if a new content has not been supplied.
      content = create_card_content(parameters)
      if content.nil?
        # There wasn't a new content. Clone the old one.
        content = clone_previous_content(original_card, card)
        return if content.nil?
      end
      parameters = process_audio_file(parameters)
      parameters.delete(:content)
      parameters.delete(:id)
      parameters.delete(:force_archived)
      if card_hash[:force_archived] == "true"
        parameters.delete(:type)
      end
      parameters[:content_id] = content[:id]
      if card_hash.has_key?(:card_tags)
        parameters[:card_tags] = []
      end
      card.update_attributes(parameters)
      card.content = content
      set_card_tags_and_render(card)
    end
  end

  def destroy
    card = Card.find(params[:id])
    unless can_edit?(card)
      return
    end
    unless card.update(type: "ArchivedCard")
      render json: {errors: card.errors.full_messages}, status: :locked
    end
    render json: {success: true}, status: :ok
  end

  # PUT /cards/selection_sounds
  # Add the selection sound to a list of cards, used only by the synchronization
  def selection_sounds
    # Cipher initialization
    cipher = OpenSSL::Cipher.new('aes-256-cbc')
    cipher.decrypt
    cipher.key = ENV["SYNC_ENCRYPTION_KEY"]
    cipher.iv = params[:iv]

    decrypted = cipher.update(params[:cards]) << cipher.final
    cards = ActiveSupport::Gzip.decompress(decrypted)
    cards = JSON.parse(cards, :symbolize_names => true)

    # Usually when we update a Card we should duplicate it,
    # but since this is part of the synch we do a normal update
    ok = true
    cards.each do |card|
      saved_card = Card.find(card[:id])
      tried_times = 0
      updated = nil
      loop do
        begin
          tried_times += 1
          updated = saved_card.update!(selection_sound: card[:selection_sound])
          break;
        rescue => err
          tried_times += 1
          logger.error "Can't update a card tried #{tried_times} times\ncard: #{card.inspect}\nsaved_card:#{saved_card.inspect}\n#{err.inspect}"
        end
        break if tried_times >= 5
      end
      unless updated
        logger.error saved_card.errors.full_messages
      end
      ok = ok && updated
    end

    if ok
      # all cards where correctly updated
      render json: {success: true}, status: :accepted
    else
      render json: {success: false}, status: :ok
    end
  end

  private

  def card_params
    add_card_permit params
  end

  def add_card_permit(card)
    card.permit( :id, :label, :level, :type, :patient_id, :selection_action, :selection_sound, :force_archived, :card_tags => [:tag], :content => [:type, :content, :content_thumbnail, :personal_file_id])
  end

  def selection_sounds_params
    params.permit( :cards => [:id, :selection_sound] )
  end

  def card_format_data
    # Extract the card parameters
    card_hash = ActionController::Parameters.new(JSON.parse(params[:card]))

    # Assign the card type, defined by the route called by the user
    card_hash[:type] = params[:type]

    unless params[:content_file].nil?
      # Convert the file into a base64, to stay compatible with the rest of the application
      contentBase64 = Base64.encode64(File.read(params[:content_file].tempfile.path))
      card_hash[:content][:content] = "data:#{params[:content_file].content_type};base64,#{contentBase64}"
    end

    return card_hash
  end

  def can_edit?(card)
    unless %(CognitiveCard CustomCard).include? params[:type]
      render json:{errors: ["#{I18n.t :error_cant_delete_card}."]}, status: :locked
      return false
    end
    if card[:type] == "PresetCard"
      render json:{errors: ["#{I18n.t :error_cant_delete_card}."]}, status: :locked
      return false
    end
    return true
  end

  # Raises an exception if the requested file doesn't exist.
  def check_file_existence(file, message)
    unless File.exist?(file)
      raise ActiveRecord::Rollback, message
    end
  end

  # If necessary, clones an existing audio file.
  def process_audio_file(parameters)
    if !parameters[:selection_sound].blank? && !parameters[:selection_sound].start_with?('data:')
      original_name = URI.decode(parameters[:selection_sound])
      file_name = Rails.root.join(ENV["PERSONAL_IMAGES_PATH"], original_name)
      if File.exists?(file_name)
        mime_type = Rack::Mime.mime_type(File.extname(file_name))
        base64 = Base64.encode64(open(file_name) { |io| io.read })
        parameters[:selection_sound] = "data:#{mime_type};base64," + base64
      else
        render json: {errors: ["#{I18n.t :error_audio_file_not_found}"]}, status: :unprocessable_entity
        raise ActiveRecord::Rollback, "#{I18n.t :error_audio_file_not_found}"
        return
      end
    end
    return parameters
  end

  protected

  # Create an hash based on the original card
  def create_clone_hash(original_card, card_params, new_type, patient_required)
    card_hash = original_card.get_an_unsaved_clone
    if params[:force_archived] == "true"
      card_hash[:type] = "ArchivedCard"
    elsif !new_type.nil?
      card_hash[:type] = new_type
    end
    card_hash[:id] = SecureRandom.uuid()
    card_hash[:content_id] = nil
    if card_hash[:patient_id].nil?
      card_hash[:patient_id] = card_params[:patient_id]
    end
    if patient_required && card_hash[:patient_id].nil?
      render json:{errors: ["#{I18n.t :error_missing_patient_id}."]}, status: :locked
      return nil
    end
    return card_hash
  end

  def clone_previous_content(original_card, card)
    # Don't clone the content anymore, use the same content for many cards
    content = original_card.content
    card[:content_id] = original_card.content_id

    return content
  end

  # Preprocesses the submitted tags to make them capitalized and avoid duplicates.
  def set_card_tags_and_render(card, card_tags = params[:card_tags])
    if !card_tags.nil?
      card_tags.each do |tag_string|
        tag_string.capitalize!
        found_tag = CardTag.where(tag: tag_string).first
        if found_tag.nil?
          found_tag = CardTag.new(tag: tag_string)
          found_tag[:id] = SecureRandom.uuid()
          found_tag.save!
        end
        if found_tag.nil?
          render json: {errors: ["#{I18n.t :error_tag_not_found} #{tag_object[:tag]}"]}, status: :unprocessable_entity
          raise ActiveRecord::Rollback, "Card creation aborted"
          return
        end
        card.card_tags << found_tag
      end
    end

    if card.save
      render json: card, serializer: Api::V1::CardSerializer, status: :created
    else
      render json: {errors: card.errors.full_messages}, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  # Returns the list of cards the query is allowed to get. ArchivedCard objects are removed.
  # This method can be overridden in child controllers to change which cards are visible.
  # By default looks for a tag id and for a type.
  def get_viewable_cards
    if params.has_key?(:card_tag_id)
      cards = Tag.find(params[:card_tag_id]).cards
    else
      cards = Card.all
    end
    cards = cards.where.not(type: "ArchivedCard")
    if params.has_key?(:type)
      cards = cards.where(type: params[:type])
    end
    return cards
  end

  # Returns all the cards whose tags contains the string specified in query parameter.
  def filter_by_query(cards, query)
    if query.nil? || query == ""
      return cards
    end
    return cards.joins(:card_tags).where("tag LIKE :query", query: "#{query}%").order("tags.tag")
  end

  def create_card_content(parameters)
    if parameters.has_key?(:content)
      parameters = parameters[:content]
      if parameters.has_key?(:personal_file_id)
        personal_file_id = parameters[:personal_file_id]
        parameters.delete(:personal_file_id)
        file_name = URI.decode(personal_file_id)
        # Process Videos
        if parameters[:type] == "Video"
          full_video_path = File.join(Rails.root, ENV['PERSONAL_IMAGES_PATH'], file_name)
          full_thumbnail_path = File.join(Rails.root, ENV['PERSONAL_IMAGES_PATH'], "video_thumbnails", "#{File.basename(file_name, File.extname(file_name))}.jpg")
          check_file_existence(full_video_path, "#{I18n.t :error_video_not_found}")
          check_file_existence(full_thumbnail_path, "#{I18n.t :error_video_thumbnail_not_found}")
          parameters[:content] = "data:#{Rack::Mime.mime_type(File.extname(full_video_path))};base64," + Base64.encode64(open(full_video_path) { |io| io.read })
          unless parameters.has_key?(:content_thumbnail)
            parameters[:content_thumbnail] = "data:#{Rack::Mime.mime_type(File.extname(full_thumbnail_path))};base64," + Base64.encode64(open(full_thumbnail_path) { |io| io.read })
          end
        else
          full_image_path = File.join(Rails.root, ENV['PERSONAL_IMAGES_PATH'], "processed", file_name)
          full_thumbnail_path = File.join(Rails.root, ENV['PERSONAL_IMAGES_PATH'], "processed", "thumbnails", "thumb_#{file_name}")
          check_file_existence(full_image_path, "#{I18n.t :error_image_file_not_found}")
          check_file_existence(full_thumbnail_path, "#{I18n.t :error_image_thumbnail_not_found}")
          parameters[:content] = "data:#{Rack::Mime.mime_type(File.extname(full_image_path))};base64," + Base64.encode64(open(full_image_path) { |io| io.read })
          parameters[:content_thumbnail] = "data:#{Rack::Mime.mime_type(File.extname(full_thumbnail_path))};base64," + Base64.encode64(open(full_thumbnail_path) { |io| io.read })
        end
      end

      content = Content.new(parameters)
      content[:id] = SecureRandom.uuid()
      content.save!
      unless content.persisted?
        render json:  {errors: content.errors.full_messages}, status: :unprocessable_entity
        raise ActiveRecord::Rollback, "Content creation aborted"
        return
      end
      return content
    end
    return nil
  end

  def order_by_default_level(cards)
    # Do nothing if a default level is not supplied
    return cards unless params.has_key?(:default_level)

    cards1 = cards.where(level: params[:default_level]).order("created_at DESC")
    cards2 = cards.where.not(level: params[:default_level]).order("created_at DESC")
    
    return Card.from("((#{cards1.to_sql}) UNION ALL (#{cards2.to_sql})) AS cards")
  end

  # If a content_type is defined, return only cards with a content of the given type
  def filter_by_content_type(cards)
    # Search based on content type
    if params.has_key?(:content)
      if params[:content].kind_of?(Array)
        original_query = cards
        params[:content].length.times do |i|
          if i == 0
            cards = cards.content_type(params[:content][0])
          else
            cards = cards.or(original_query.content_type(params[:content][i]))
          end
        end
      else
        cards = cards.content_type(params[:content])
      end
    end
    return cards
  end

  # Return only cards with a content of the given duration
  def filter_by_content_duration(cards)
    filtered = cards
    if params.has_key?(:content_longer_than)
      filtered = filtered.content_longer_than( params[:content_longer_than] )
    end
    if params.has_key?(:content_shorter_than)
      filtered = filtered.content_shorter_than( params[:content_shorter_than] )
    end
    filtered
  end

end
