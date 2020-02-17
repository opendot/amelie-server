class CableChannel < ApplicationCable::Channel
  # Called when the consumer has successfully
  # become a subscriber of this channel.
  def subscribed
    unless current_user.is_a?(DesktopPc)
      ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {type: "USER_CONNECTED", data: nil}.to_json)
    end

    stream_from "cable_#{params[:direction]}"
  end

  # Called when the consumer has left this channel.
  def unsubscribed
    if ActionCable.server.connections.length == 1
      puts "last client"
      ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {type: "LAST_CLIENT"}.to_json)
      ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_MOBILE_SOCKET_CHANNEL_NAME']}", {type: "LAST_CLIENT"}.to_json)
    end
  end

  # Called when the consumer has sent some data.
  def receive(data)
    if params[:direction].ends_with?(ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME'])
      ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_MOBILE_SOCKET_CHANNEL_NAME']}", data)
    end
  end
end