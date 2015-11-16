# Stream Based Object Synchronization

## 1. Introduction

### 1.1 Who Am I, What I Do?
* Lead iOS engineer at Layer, specializing in data synchronization.

## 2 Data Synchronization
* What is data synchronization? (having the same state on all clients/nodes)
* Types of data synchronizations (file, document, data model, database)
* Ways to synchronize (static/absolute: copy, diff; dynamic/relative: deltas)

### 2.1 Application Use cases
* Messaging, photo sharing, file sharing, multiplayer game synchronization,
  application data synchronization across devices.

### 2.2 What Are Deltas?
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
* Locking the stream (e.g. table or row in database) drops the response time
  drastically in noisy streams.

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
* Fast because of the low bandwidth and CPU usage cost when getting data
  (deltas) delivered in real-time.
* Easy to implement load balancing and replication on server.


## 7. Shortcomings
* To get to a fully reconciled state from a cold-state can take a lot of
  resources (time, bandwidth and CPU).
* Very difficult to implement partial sync process (since you don't have a
  complete view of the stream at the beginning of the sync process).


## 8. Possible Optimizations
* Building immutable indexes based on the specific attributes of the model,
  so that clients can prioritize relevant data or ignore irrelevant data.
* Building fast-forward snapshots of model from events by pre-reconciling it
  on server (coalesce mutations for same objects and its attributes,
  reduce edit distance) -- hybrid approach.
