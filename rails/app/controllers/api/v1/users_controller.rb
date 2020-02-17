class Api::V1::UsersController < ApplicationController
  respond_to :json

  skip_before_action :authenticate_user!, only: [:on_network]
  skip_authorize_resource only: [:on_network]

  def index
    users = User.all
    
    # Filter based on user type
    case current_user
    when Parent
      users = users.where(type: %w(Teacher Therapist))
    when Superadmin
      # Can see all users
    else
      users = users.where(type: %w())
    end

    # filter by type
    if params.has_key?(:type)
      users = users.where(type: params[:type])
    end

    # search for users names
    if params.has_key?(:search)
      users = filter_by_query(users, params[:search])
    end

    # filter by disabled
    if params.has_key?(:disabled)
      if params[:disabled] == "true"
        users = users.all.select{ |usr| usr.disabled? }
      else
        users = users.all.select{ |usr| !usr.disabled? }
      end
    end


    case current_user
    when Superadmin
      paginate json: users, each_serializer: Api::V1::UserSerializer, status: :ok
    else
      paginate json: users.select(:id, :name, :surname, :email, :type), each_serializer: Api::V1::SmallUserSerializer, status: :ok
    end
    #paginate json: users, each_serializer: Api::V1::UserSerializer, status: :ok
  end

  def show
    case current_user
    when Superadmin
      render json: User.find(params[:id]), serializer: Api::V1::UserSerializer, status: :ok
    else
      render json: User.find(params[:id]), serializer: Api::V1::SmallUserSerializer, status: :ok
    end

  end

  def update
    if current_user.id != params[:id] && !current_user.is_a?(Superadmin)
      # An user can only be updated by himself or by the superadmin
      return render json: { errors: [I18n.t(:error)] }, status: :unauthorized
    end

    user = User.find(params[:id])
    user.assign_attributes(user_params)
    if user.save
      render json: user, serializer: Api::V1::UserSerializer, status: :accepted
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /users/on_network
  # Open route to notify that a user is on the same network of the server
  def on_network
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {type: "USER_ON_NETWORK"}.to_json)
    render json: { success: true }, status: :ok
  end



  def destroy
     unless User.exists?(params[:id])
      render json: {errors: [I18n.t("error"), "id: #{params[:id]}"]}, status: :not_found
      return
     end
     @user = User.find(params[:id])
     puts !current_user.is_a?(Superadmin)
     if current_user.id != params[:id] && !current_user.is_a?(Superadmin)
       return render json: { errors: [I18n.t(:error)] }, status: :unauthorized
     end
     @user.destroy!
     render json: {success: true}, status: :ok
  end

  # PUT /users/disable
  # disable/enable all patients of an array of users
  def disable
    updated_count = 0
    users = params[:users]
    users.each do |u|
      if Parent.exists?(u[:id])
        User.find(u[:id]).set_disabled(u[:disabled])
        updated_count += 1
      end
    end

    render json: { updated: updated_count }, status: :accepted
  end


  # Returns all the users whose name or surname contains the string specified in query parameter.
  def filter_by_query(users, query)
    if query.nil? || query == ""
      return users
    end
    return users.where("name LIKE :query OR surname LIKE :query", query: "#{query}%")
  end

  private
  
  def user_params
    params.permit(:name, :surname, :birthdate, :type, :organization, :role, :description)
  end
end
