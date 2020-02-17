module ModelStringConverter

  def extract_array_from( line )
    # A single line contains a whole array of objects
    objects = JSON.parse(line, :symbolize_names => true)

    # Extract the ids
    # Remove the updated_at value, it must be set to DateTime.now for future synchronizations
    # Remote server must update the updated_at value to send the updated data to all other users,
    # local server can keep the updated_at value of the remote server, or it will try to reupload them
    ids = []
    objects.each do |obj| 
      ids.push(obj[:id])
      obj.delete(:updated_at) if Rails.env.ends_with?("remote")
    end
    
    return [objects, ids]
  end

  def split_existent_and_non( what, objects, ids)
    # Find objects that already exist
    existent = what.constantize.where(id: ids)

    # Include soft-deleted
    if what.constantize.column_names.include? 'deleted_at'
      existent = existent.with_deleted
    end

    # puts ""
    # puts ""
    # puts "***************************    CREATING    **************************"
    # puts what
    # puts "+++++++++++++++++++++++++++++++++++++++++++"
    # puts ids.inspect
    # puts existent.ids
    # puts "+++++++++++++++++++++++++++++++++++++++++++"
    # Get the ids of objects already present in the database
    existent_ids = existent.ids
    # Find objects that aren't already in the database
    non_existent = objects.select { |obj| !existent_ids.include?(obj[:id])}
    existent = objects.select { |obj| existent_ids.include?(obj[:id])}

    return [existent, non_existent]
  end


end