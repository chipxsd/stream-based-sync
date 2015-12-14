require 'em-websocket'
require 'json'

EM.run {
  @lightSwitchState = false;
  @channel = EM::Channel.new

  EM::WebSocket.run(:host => "0.0.0.0", :port => 8080) do |ws|
    # Method called when a client successfully connects to the server.
    ws.onopen { |handshake|
      puts "LightSwitchServer: connection open"
      puts "LightSwitchServer: origin: #{handshake.origin}"
      puts "LightSwitchServer: headers: #{handshake.headers}"

      # Sending the last known lightSwitchState to the newly connected client.
      # JSON Structure example: { lightsOn: true }
      lightsOnString = { :lightsOn => @lightSwitchState }.to_json
      ws.send lightsOnString

      # Registering the newly connected client to the global channel, and
      # implementing a method that gets called when a participant
      # of a channel receives a message.
      sid = @channel.subscribe { |msg|
        # Sends a text body over the web socket to the connected client.
        ws.send msg
      }

      # Method called when a text body is received from a connected client.
      ws.onmessage { |msg|
        lightsOn = JSON.parse(msg)
        @lightSwitchState = lightsOn["lightsOn"]
        lightsOnString = { :lightsOn => @lightSwitchState }.to_json
        puts "LightSwitchServer: client #{sid} sent light switch state change: #{lightsOn}"

        # Pushing the new reconstructed JSON structure.
        @channel.push lightsOnString
      }

      # Method called in case the websocket server received an error.
      ws.onerror do |error|
        puts "LightSwitchServer: error #{error}"
      end

      # Method called when a client disconnects from the session.
      ws.onclose {
        # Removing the participant from the channel.
        @channel.unsubscribe(sid)
        puts "LightSwitchServer: #{sid} connection closed"
      }
    }
  end
  puts "LightSwitchServer: started"
}
