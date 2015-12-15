# Stream Based Data Synchronization

## 1. Introduction

### 1.1 Who Am I, What I Do?

I'm the lead iOS engineer at Layer, primarily working on the messaging SDK,
which mostly consists of multiple layers of data synchronization. I started
working on various data synchronization approaches at the early stage of
the company and there has been many prototypes built across the platform,
Android and iOS.

## 2 Data Synchronization

### 2.1 What is Data Synchronization?

Term _synchronization_ in computer science is a bit ambiguous, it can for
example mean coordination of simultaneous processes to complete a task in
the correct order (to avoid any potential race conditions). But in this topic
we'll be mainly talking about data synchronization, as in having the
same state across multiple clients.

#### 2.1.1 Example

An example would be a mobile app with a toggle switch, say a **light switch**.
Now, if I have 5 devices in front of me, I'd like to have the light switch
state shared across all those devices. If I turn the lights on or off
one device, it should reflect the changes on other 4 devices. That's a
pretty basic example of data synchronization over network.

![fig.1 - Example App "Light Switch"](./figure_01.png "fig. 1 - Example App 'Light Switch'")

Solutions for such problem come pretty natural to experienced engineers, but
for some it may not be as trivial. So let's play with the _Light Switch_
sample app idea for a little. To narrow down the requirements for this app,
let's say that the light switch state has to be shared across devices
via TCP/IP network. I pointed out TCP/IP network because there are also other
technologies and protocols we could use that provide close proximity
communication to achieve this (such as Bluetooth, AdHoc WiFi,
Multi-peer Connectivity on Apple devices, etc.).

#### 2.1.2 How Would We Design Such a System?

Let's make a list of components we need to have to achieve this:

- **a simple server** -- which can be a lightweight service (process)
  written in C using standard library, or something written in higher-lever
  languages (Scala, Ruby, Python, Java, etc.) using off-the-shelf libraries.
  For the sake of simplicity, we'll use a simple web socket server in
  Ruby that accepts JSON structure with _Light Switch_ state information,
  and fans out the new state to other clients. No persistence of the
  _Light Swtich_ state required.

- **mobile clients** -- an app that connects to our lightweight server
  capable of receiving and sending _Light Switch_ state changes through
  the web socket. For visualization of these state changes we'll switch
  between two different background images (one indicating lights are on,
  and the other one for when the switch is off).

![fig.2 - Example App Architecture](./figure_02.png "fig. 2 - Example App Architecture")

Both client side and server side code should be very simple to implement.

#### 2.1.3 Client Side

Let's check the client side code first. We mentioned we're going to use
[WebSockets](https://en.wikipedia.org/wiki/WebSocket) to keep a persistent
connection between the client and the server. The one that kind of sticks
out for me is [Starscream](https://github.com/daltoniam/Starscream), it looks
like a clean, very easy to use WebSocket client written in Swift.

We shouldn't need more than two functions to do the job of sending and
receiving Light Switch state updates in our transport layer.

```swift
/**
 Transmits the light switch state to the server

 - Parameter lightsOn: A boolean value representing the light switch state.
 */
public func sendLightSwitchState(lightsOn: Bool) {
    let lightSwitchStateDict = ["lightsOn" : lightsOn]
    var JSONString: String?
    do {
        let JSONData = try NSJSONSerialization.dataWithJSONObject(lightSwitchStateDict, options: NSJSONWritingOptions.PrettyPrinted)
        JSONString = String(data: JSONData, encoding: NSUTF8StringEncoding)!
    } catch let error {
        print("Failed serializing dictionary to a JSON object with \(error)")
    }
    if JSONString != nil {
        self.webSocketClient.writeString(JSONString!)
    }
}
```

What the function above does is it wraps the `Boolean` value into a dictionary,
serializes it into a JSON structure (which is a `String`) and then sends
it over the open Web Socket connection.

Now we need a function to do the similar operation on the inbound side.
In an event of receiving a JSON structure, it should try deserializing it
into a dictionary object and call a delegate method to let it know of the new
Light Switch state.

```swift
/**
 WebSocket's delegate method invoked by the `WebSocket` client upon
 receiving a string body.

 - Parameter socket: A `WebSocket` client performing the call on the method.
 - Parameter text: The text body received by the `WebSocket` client.
 */
public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
    let JSONData = text.dataUsingEncoding(NSUTF8StringEncoding)
    var lightSwitchStateDict: Dictionary<String, AnyObject>?
    do {
        lightSwitchStateDict = try NSJSONSerialization.JSONObjectWithData(JSONData!, options: NSJSONReadingOptions.AllowFragments) as? Dictionary<String, AnyObject>
    } catch let error {
        print("Failed deserializing the JSON object with \(error)")
    }
    if lightSwitchStateDict != nil {
        self.delegate?.lightSwitchClientDidReceiveChange(self, lightsOn: lightSwitchStateDict?["lightsOn"] as! Bool)
    }
}
```

The UI controller implementation should be symmetrical to the transport
layer implementation. Again, two functions -- one sending the controller's
Light Switch state to the transport layer, and the other one should be an
implementation of the delegate callback which the transport layer calls.

```swift
/// The local Light Switch state.
private var lightSwitchState:Boolean;

/**
 LightSwitchClientDelegate function implementation, which gets executed
 whenever a new light switch state comes in from the network. The new state
 gets stored in a local variable `self.lightSwitchState`.

 - Parameter client: The `LightSwitchClient` executing the function.
 - Parameter lightsOn: The new Light Switch state coming from network.
 */
func lightSwitchClientDidReceiveChange(client: LightSwitchClient, lightsOn: Bool) {
    self.lightSwitchState = lightsOn
}

/**
 Toggles the private ivar `_lightSwitchState` boolean, updates the
 background image, plays a sound and transmits the change over network.
 */
func toggleAndSendLightSwitchState() {
    self.lightSwitchState = !self.lightSwitchState
    self.lightSwitchClient?.sendLightSwitchState(self.lightSwitchState)
}
```

This pretty much sums up the client side implementation.

#### 2.1.4 Server Side

Let's take a quick look at how the server-side implementation should look
like. I chose to write the server side implementation in Ruby
using a library called [em-websocket](https://github.com/igrigorik/em-websocket).

```ruby
# A global variable keeping the light switch state.
@lightSwitchState = false;

# Channel instance available across all web socket connections. We'll use
# this channel to emit the changes to all open connections.
@channel = EM::Channel.new

EM::WebSocket.run(:host => "0.0.0.0", :port => 8080) do |ws|
  ws.onopen { |handshake|
    # Sending the last known lightSwitchState to the newly connected client.
    # JSON Structure example: { lightsOn: true }
    ws.send ({ :lightsOn => @lightSwitchState }.to_json)

    sid = @channel.subscribe { |msg|
        # Sends a text body over the web socket to the connected client.
        ws.send msg
    }

    ws.onmessage { |msg|
      lightsOn = JSON.parse(msg)
      @lightSwitchState = lightsOn["lightsOn"]
      # Pushing the new reconstructed JSON structure.
      @channel.push { :lightsOn => @lightSwitchState }.to_json
    }
 }
end
```

There's two main parts to the code above. We used channels to construct
a notion of followers (or listeners, if you will), and when a client
connects to the server it gets added to the channel (`@channel.subscribe`).
Then, as soon as the server receives a light switch change (`ws.onmessage`)
from a client, it unwraps the JSON structure, takes out the Light Switch state
(`:lightsOn`), stores it into the globally variable (`@lightSwithcState`) and
then pushes a newly constructed JSON object to the channel, which then
gets emitted to all of the channel participants. This is how we
achieve the fan-out.

-------------------------------------------------------------------------------
this is still chapter 2.1
-------------------------------------------------------------------------------

* Use cases: messaging, photo sharing, file sharing, multiplayer game synchronization,
  application data synchronization across devices.
* Types of data synchronizations (file, document, data model, database)
* Ways to synchronize (static/absolute: copy, diff; dynamic/relative: deltas;)

### 2.1 What Are Deltas?
* Short pieces of information describing model mutations.
* How to deal with deltas? How to store it and transfer over network?


## 3. Stream Based Synchronization

### 3.1 The Motivation
* In our case we're solving the synchronization of shared content between
  clients (mobile and desktop devices, web browers) and servers (nodes).
* Get deltas off of clients as quick as possible.
* Fast writes on the server (concurrent).
* Easier data distribution across nodes.

### 3.2 Data Schema
* Think of streams as old magnetic tapes with WORM behavior (immutable,
  append only).
* Tiny bits of information describing different operations -- aka events.
* Event describe mutations (inserts, deletes, updates).
* Server defined sequence based identifiers.

### 3.3 Content Synchronization
* Sequence based identifiers allow for lightweight event discovery.


## 4. Reconciling Events to Data Model

### 4.1 Outbound Reconciliation
* Turning model mutations into events.
* Maintaining short edit distances.

### 4.2 Inbound Reconciliation
* Taking mutation data from events and applying it on the model.
* Conflict resolution.


## 5. Total Order
* How to keep the events published by clients in the correct order?

### 5.1 Synchronized Sequential Writes
* Locking the stream (e.g. table or row in database) increases the response
  time drastically in noisy streams.

### 5.2 Don't Even Think About Timestamps!
* Relying on timestamps to keep the order of events requires an
  extra level of synchronization, which is in most cases unreliable to
  reconstruct the order of events.

### 5.3 Version Vectors
* Reconstructing event order based on happened-before information clients
  include in events.
* They enable causality tracking between clients (nodes) -- basic mechanism in
  optimistic (lazy) replications.
* Very useful when resolving conflicts.


## 6. Advantages
* Fast because of the low bandwidth and CPU usage cost when getting the data
  (deltas) delivered in real-time.
* Easy to implement load balancing and replication on server.


## 7. Shortcomings
* To get to a fully reconciled model from a cold-state can take a lot of
  resources (time, bandwidth and CPU).
* Very difficult to implement partial sync process (since you don't have a
  complete view of the stream at the beginning of the sync process).


## 8. Possible Optimizations
* Building immutable indexes based on the specific attributes of the model,
  so that clients can prioritize relevant data or ignore irrelevant data.
* Building fast-forward snapshots of model from events by pre-reconciling it
  on server (coalesce mutations for same objects and its attributes,
  reduce edit distance) -- hybrid approach.
