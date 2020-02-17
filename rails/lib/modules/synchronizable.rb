module Synchronizable
    extend ActiveSupport::Concern
    # Common methods used to synchronize an object to the online server
  
    # Allow to add scopes to a module, it needs to extend ActiveSupport::Concern
    included do |klass|
      scope :not_sync,  ->  (last_sync_date){ where("updated_at > ?", last_sync_date) }
      scope :for_patient,  ->  (patient_id){ where(patient_id: patient_id) }

      # Allow to define both class and instance methods by only including Synchronizable
      klass.extend(SynchronizableClassMethods)
    end

    # All class methods
    module SynchronizableClassMethods

      def keys
        keys = self.column_names.map { |col| "`#{col}`"}
        keys = keys.join(",")
        return "(#{keys})"
      end

      def create_from_array( hash_array )
        hash_array.each do |record|
          begin
            self.create(record)
          rescue ActiveRecord::RecordNotUnique => invalid
            obj = self.find(record[:id])
            obj.update(record)
            logger.warn "Record already present for #{invalid.record.class.name} record. Errors: #{invalid.record.errors.to_json}, Data: #{record.to_json}"
          end
        end
        end

      def update_from_array( hash_array )
        hash_array.each do |record|
          obj = self.find(record[:id])
          begin
            obj.update(record)
            # FIXME: `update` already calls `save` internally, why doing it twice? It doens't cause any real issue, still odd though.
            obj.save!
          rescue ActiveRecord::RecordInvalid => invalid
            logger.warn "Validation failed for #{invalid.record.class.name} record. Errors: #{invalid.record.errors.to_json}, Data: #{record.to_json}"
          end
        end
      end

    end

end