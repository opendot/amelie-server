module ParanoidSynchronizable
  extend ActiveSupport::Concern
  # Common methods used to synchronize an object who implements Paranoia gem to the online server

  # Allow to add scopes to a module, it needs to extend ActiveSupport::Concern
  included do |klass|
    klass.include(Synchronizable)
    klass.acts_as_paranoid
    scope :not_sync,  ->  (last_sync_date){ with_deleted.where("updated_at > ?", last_sync_date) }

    # Allow to define both class and instance methods by only including ParanoidSynchronizable
    klass.extend(ParanoidSynchronizableClassMethods)
  end

  # All class methods
  module ParanoidSynchronizableClassMethods

    def create_from_array( hash_array )
      self.create(hash_array)
    end

    def update_from_array( hash_array )
      this_is_remote_server = Rails.env.ends_with?("remote")

      hash_array.each do |record|
        obj = self.with_deleted.find(record[:id])
        if this_is_remote_server
          if obj.deleted?
            obj.update(record.except(:deleted_at))
          else
            obj.update(record)
          end
        else
          obj.update(record)
        end

        obj.save
      end
    end

  end

end