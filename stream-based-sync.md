# Stream Based Data Synchronization (working title)

_Still a work in progress_

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

![fig.1 - Example App "Light Switch"](./images/fig-01-lightswitch-app.gif "fig. 1 - Example App 'Light Switch'")

Solutions for such problem come pretty natural to experienced engineers, but
for some it may not be as trivial. So let's play with the _Light Switch_
sample app idea for a little. To narrow down the requirements for this app,
let's say that the light switch state has to be shared across devices
via TCP/IP network. I pointed out TCP/IP network because there are also other
technologies and protocols we could use which provide close proximity
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
connection between the client and the server. For me the one that kind of sticks
out is [Starscream](https://github.com/daltoniam/Starscream), it's a clean,
very easy to use WebSocket client written in Swift.

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
a notion of followers (or participants, if you will), and when a client
connects to the server it gets added to the channel (`@channel.subscribe`).
Then, as soon as the server receives a light switch change (`ws.onmessage`)
from a client, it unwraps the JSON structure, takes out the Light Switch state
(`:lightsOn`), stores it into the globally variable (`@lightSwithcState`) and
then pushes a newly constructed JSON object to the channel, which then
gets emitted to all of the channel participants. This is how we
achieve the fan-out.

So there you go, a pretty basic approach to data synchronization.

### 2.2 Other Use Cases

In our example (chapter 2.1.1) we demonstrated how to synchronize an ON/OFF
switch across multiple devices -- it's not a common use case, but it was good
enough to prove a point.

There are a lot of applications we use every day that use data synchronization
to share the same state across devices, let's identify a few with examples:

- **e-mail** -- most IMAP clients get up to date by fully synchronizing the
  list of all e-mails and their unread state. All clients for the same
  user receive new messages at the same time; marking a message on one client
  as read reflects the change on other clients as well.
- **messaging** -- having the same view of messages and conversations
  across clients; web, mobile, etc. Receiving messages and their delivery
  and read receipts from other participants on all the clients.
- **photo sharing** -- shared photo stream with all participants.
- **file sharing** -- backing up a content of a folder from local filesystem
  to cloud.
- online **text** and **spreadsheet editors** -- having multiple users working
  on the same text or spreadsheet document at once. Seeing the text coming in
  as users type in different paragraphs.
- **multiplayer games** -- same state of the world for all players on the
  same server. Things as trivial as picking up ammo or weapons from the ground,
  etc.

The list goes on...

### 2.3 Types of Data Synchronization

Now that we had identified a few of these use cases, let's figure out
what kind of data we even deal with in those cases.

We mentioned **file sharing** -- that means file and directory structure
replication across clients. If I add a file to the _shared_ folder on one
of my computers, I'd like that file to appear on other computer too. Same if
I modify that file on one computer, I want that file along with its content
to be copied on other machines too. The easiest way to implement this would
be to copy the whole directory (along with all the files and sub-directories)
every time we change something (add or remove a file, change the content in
a file). This would work, but that simply does not scale. If I keep adding
files to the directory, the copy process would become longer with the count
of files.

Better way to synchronize a file / directory structure is to compare them,
recognize differences and only copy what doesn't match. This is what we call
[file-synchronization](https://en.wikipedia.org/wiki/File_synchronization),
[Rsync](https://en.wikipedia.org/wiki/Rsync) is a very nice example of this.
It's similar to how [Dropbox](https://en.wikipedia.org/wiki/Dropbox_(service)),
[iCloud Drive](https://en.wikipedia.org/wiki/ICloud#iCloud_Drive) and all
these file hosting solutions minimize the work in order to get the files
in sync with all machines.

![fig.3 - File Sharing](./images/fig-03-file-sharing.jpeg "fig. 3 - File Sharing")

Copying file's content over to other clients **every time** we touch it on one
machine can be a rather expensive operation -- well, it depends on the size
and type of the content -- but let's say we're dealing with a multiline text
document, a source code file for example. Why copy 10 kilobytes of content,
represented by hundreds of lines of code, where we just wanted to change
a single line of code:

```swift
    83: //
    84: // Toggles the private ivar `_lightSwitchState` boolean, updates the
    85: // background image, plays a sound and transmits the change over network.
    86: //
    87: func toggleAndSendLightSwitchState() {
    88:     self.lightSwitchState = !self.lightSwitchState
>   89:     self.lightSwitchClient.sendLightSwitchState(self.lightSwitchState)
    90: }
```

In above example, I forgot to specify optional chaining in the line `89:`.
That is just a single line of change. One way of describing this content
change could be through the
[unified diff annotation](https://en.wikipedia.org/wiki/Diff_utility), which is
still lighter than copying the whole file over.

```patch
--- 89:     self.lightSwitchClient.sendLightSwitchState(self.lightSwitchState)
+++ 89:     self.lightSwitchClient?.sendLightSwitchState(self.lightSwitchState)
```

Due to the nature of the document's data structure (lines of text separated by
newline characters `\0x0a`), this was fairly easy.
That's how [distributed revision control systems](https://en.wikipedia.org/wiki/Distributed_version_control)
describe and apply changes to text files. But at the end of the day,
we **synchronized document's content** change.

What about our _Light Switch_ app example (from chapter 2.1.1)? It's nothing
more than **data-model synchronization**.

![fig.4 - Data Model](./images/fig-04-data-model "fig. 4 - Data Model")

As with file and document synchronization, we can just make a copy
of the data-model and transfer it over the wire to other
clients, which is exactly what we did in our example app. We could afford
this in our _Light Switch_ example app, seeing that the model was
extremely small -- it's a single instance of a boolean value
`private var lightSwitchState:Boolean;`, you can't get smaller than that.

Should the model be more sophisticated (having multiple fields, mutable
collections, relationships with other structures), copying the whole structure
along with its values (whole object graph) over and over again becomes
expensive.

### 2.4 Approaches to Data Synchronization

What we've learned from the previous chapter is, that there are different
ways to get our data up-to-date. The most naive way is to just **copy it**,
which is in a lot of cases less than ideal. Better way to get the existing
data up-to-date is to only **apply changes** to it. Let's visit
both approaches.

#### 2.4.1 Absolute Synchronization (copying)

**Copying** and replacing the data (file, document, data-model) is perfectly
fine, when we don't care for the amount of data we need to transfer, since
the server will always return a fully populated dataset. Also works good when
the synchronization is uni-directional, meaning the client
always asks the server for the source of truth (e.g. refreshing the
weekly weather forecast, or refreshing a list of RSVPs).

The other drawback of copy based synchronization is not only the potential
higher bandwidth cost due to transmitting the same data for the most part
(which we call data redundancy), but also if we need to be aware of the
changes when replacing our old dataset with the newly up-to-date one,
we'd need to compare (differentiate) the two datasets first, before
replacing the old one. That process burns twice as much memory (since
you need to hold both sets in memory) and CPU time for as much as
there are elements in both sets (which gives us the O(n ⋁ m)).

![fig.5 - Differencing Datasets](./images/fig-04-differencing-datasets.png "fig. 5 - Differencing Datasets")

Suppose you're invited to a dinner party and you ask the receptionist
_"Who's here?"_. That person will respond: _"There's Alex, Blake, Caroline,
Dan, Emily and George."_. In your mind you've made a list of guests from what
you just heard. Now one of the guests leaves, but you weren't paying
attention, so you go ask the receptionist, _"What about now?"_, and the
person responds: _"There's Alex, Caroline, Dan, Emily and George"_ -- it's
like talking to an idiot. So in order to figure out what has changed, if
anyone left or someone new joined the party, you'd need to remember the
list of guests from before and run it against the one you just heard.

#### 2.4.2 Relative Synchronization (based on changes)

You'd be better off with an answer like: _"Blake just left"_, instead of
listening the person go through the whole list of people that are still
at the party. That's assuming the person you're asking knew when was
the last time you were paying attention. It just seems like a lot of
work for the receptionist to keep track of what others take notice off.
So, to make it a little easier you should rephrase the question to: _"What has
happened after I arrived?"_.

The receptionist would just go through the list where he keeps the names
of the guests coming in and going out, look for the record when you arrived
and narrate all the events that happened after that.

That is an example, when you update data only with small differences, based
on previous events that you are already familiar with, to avoid copying
the whole data set. These small differences or **changes** are also known
as deltas.

### 2.5 What Are Deltas?

Delta encoding is a way to describe differences between two datasets
(file, document, data-model, etc.). We can use these short pieces of
information to apply onto our dataset (in form of mutations) to
get it up-to-date which we have learned that it significantly reduces
data redundancy in the synchronization processes.

#### 2.5.1 How to Encode Deltas?

Of course, depending on our application, we'd want to encode the deltas
in the way that is suitable for our application data model. Taking a look
at the few examples we've set out in **chapter 2.3**, applications can
work with pure arbitrary data (binary files), document (text files, xml,
spread sheets), data-model (data structures), etc.

But generally, we'd want our deltas to give us instructions on how to
modify our current data set based on three simple operations:

- **insert** -- adds new values to our data set
- **update** -- updates existing values in our data set
- **delete** -- deletes existing values from our data set

We already went trough an example on encoding deltas for text changes in
**chapter 2.3** where we had to change a single line of text in a multi-line
text file (swift source code).

##### Example of Delta Encoding of Binary Data

Given a file of arbitrary data (of 80 bytes):

```hexdump
0000000: 4749 4654 2B31 0d00 0d00 9100 00b6 6257  GIFT+1........bW
0000010: 0804 0456 2c27 e5aa 7f21 f904 0000 0000  ...V,'...!......
0000020: 002c 0000 0000 0d00 0d00 0002 318c 8f29  .,..........1..)
0000030: 3000 7986 944f 8823 260d 0feb b620 0b03  0.y..O.#&.... ..
0000040: 2e97 e1a4 0f79 920c 60a5 28e5 c452 abc6  .....y..`.(..R..
```

we'd like to change the value of tree bytes starting at offset `0x03`,
and append 16 more bytes at the end of the array. We could encode the
delta as:

```javascript
[
  {
    operation: "update",
    offset: 0x03,
    values: [ 0x38, 0x39, 0x61 ]
  }, {
    operation: "insert",
    offset: 0x50,
    values: [ 0xCE, 0xE1, 0x50, 0x96, 0x89, 0x48, 0x9D, 0x02, 0x43, 0x62,
      0x8D, 0x98, 0x28, 0x00, 0x00, 0x3B ]
  }
]
```

_**Note**_ that I chose to describe the data structure above using a
JSON format. We can serialize the delta information in any format
that suits the purpose. Here are a few from the top of my head:
[Thrift](https://en.wikipedia.org/wiki/Apache_Thrift),
[Protobuff](https://en.wikipedia.org/wiki/Protocol_Buffers),
[CapnProto](https://github.com/sandstorm-io/capnproto), however you can chose
to implement your own proprietary serialization protocol.

We could use exactly the same delta encoding approach to describe a change of
a text file -- if you remember our one line change in a swift source
code in **chapter 2.3**. This type of delta encoding compressed the data
even more than using unified diff patches.

```javascript
{
  operation: "insert",
  offset: 2781,
  values: [ "?" ]
}
```

##### Example of Delta Encoding of a Custom Data Model



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
