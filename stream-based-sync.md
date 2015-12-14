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
example mean having a piece of code running in serial (synchronous)
or in parallel (asynhcronous). But in our case, we'll be mostly
talking about data synchronization over network, as in having the
same state across multiple clients.

#### 2.1.1 Example

An example would be a mobile app with a toggle switch, say a **light switch**,
Now, if I have 5 devices in front of me, I'd like to have the light switch
state shared across all those devices. So if I turn the lights on or off
one device, it should reflect the change on other 4 devices. That's a
pretty basic example of network data synchronization.

![fig.1 - Example App "Light Switch"](./figure_01.png "fig. 1 - Example App 'Light Switch'")

Solutions for this problem come pretty natural for experienced engineers, but
for some it may not be as trivial. So let's play with the _Light Switch_
sample app idea for a little. To narrow down the requirements for this app,
let's say that the light switch state has to be shared across devices
via Internet -- since by having these devices in close proximity,
we could use various technologies and protocols to achieve this (such as
Bluetooth, AdHoc WiFi, Multi-peer Connectivity on Apple devices, etc.).

#### 2.1.2 How Would We Design Such a System?

Let's make a list of components we need to have to achieve this:

- **a simple server** -- which can be a lightweight service (process)
  written in C using standard library, or something bigger written using
  a framework (in Scala, Ruby, Python, Java, etc.). For the sake of
  simplicity, in this example we'll have our server listen to and
  accept plain TCP connections, we won't need persistence or database
  of any kind.

- **mobile clients** -- an app that connects to our lightweight server
  capable of receiving and sending _Light Switch_ state changes.

![fig.2 - Example Architecture](./figure_02.png "fig. 2 - Example Architecture")



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
