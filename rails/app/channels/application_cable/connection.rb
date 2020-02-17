module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect

        params = request.query_parameters()
        access_token = params["access-token"]
        uid = params["uid"]
        client = params["client"]

        self.current_user = find_verified_user(access_token, uid, client)
        logger.add_tags 'ActionCable', current_user.email

    end
    
    protected

    #Checks whether a user is authenticated with devise token auth
    def find_verified_user token, uid, client_id 
        
        user = User.find_by email: uid
        if user && user.valid_token?(token, client_id)
          return user
        else
            reject_unauthorized_connection
        end
        
    end   
  end
end
