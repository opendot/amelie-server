class FavouriteTreeCountValidator < ActiveModel::Validator
  def validate(record)
    if record.is_favourite == true
      favourite_trees_count = UserTree.where(user_id: record[:user_id], favourite: true).count
      if favourite_trees_count > 2
        record.errors[:base] << "#{I18n.t :error_too_many_favourite_trees}."
      end
    end
  end
end