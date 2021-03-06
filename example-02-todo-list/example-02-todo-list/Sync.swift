//
//  Sync.swift
//  example-02-todo-list
//
//  Created by Klemen Verdnik on 1/2/16.
//  Copyright © 2016 Klemen Verdnik. All rights reserved.
//

import Foundation

public protocol ModelReconciler: class {
    /// Receiver of generated events
    weak var outboundEventReceiver: OutboundEventReceiver? { get set }
    
    /**
     Applies events from the Array onto the model in the order they're
     stored in the array.
     
     - parameter events: An array of `Event` instances.
     
     - returns: `true` in case the event was successfully applied onto the model
                otherwise `false`.
     */
    func apply(events: Array<Sync.Event>) -> Bool
}

public protocol OutboundEventReceiver: class {
    /// Instance of the model reconciler.
    var modelReconciler: ModelReconciler { get }

    /**
     Notifies the receiver that a new event has been created by the model
     reconciler.
     
     - parameter reconciler: The instance of the model reconciler making
     performing the invocation of this method.
     - parameter event:      The `Event` instance created.
     */
    func reconcilerWillCreateEvent(reconciler: ModelReconciler) -> Sync.SeqPointer

    /**
     Notifies the receiver that a new event has been created by the model
     reconciler.
     
     - parameter reconciler: The instance of the model reconciler making
                             performing the invocation of this method.
     - parameter event:      The `Event` instance created.
     */
    func reconciler(reconciler: ModelReconciler, didCreateEvent event: Sync.Event)
}

public struct Sync {
    public class Client: NSObject, OutboundEventReceiver, TransportDelegate {
        /// Instance of the Stream object, where we keep the stream information.
        public private(set) var stream: Stream = Stream()
    
        /// Instance of the transport layer.
        public private(set) var transport: Transport
    
        /// Instance of the model reconciler.
        public private(set) var modelReconciler: ModelReconciler
        
        /// Collection of all events known to client (sent and received).
        public private(set) var publishedEvents: Array<Event> = []
        
        /// Collection of all queued events meant for publication.
        /// This collection is drained as events get published.
        public private(set) var queuedEvents: Array<Event> = []
        
        /// Serial dispatch queue guarding the `self.queuedEvents` collection.
        private var queuedEventsQueue = dispatch_queue_create("sync.client.queuedEventsQueue", DISPATCH_QUEUE_SERIAL)
        let queuedEventsQueueSpecificKey = ("sync.client.queuedEventsQueue.specificKey" as NSString).UTF8String
        var queuedEventsQueueSpecificValue = "sync.client.queuedEventsQueue.specificValue"
        
        /// Concurrent queue for non-blocking event publication
        private var publicationQueue = dispatch_queue_create("sync.client.publicationConcurrentQueue", DISPATCH_QUEUE_CONCURRENT)

        init(transport: Transport, modelReconciler: ModelReconciler) {
            self.transport = transport
            self.modelReconciler = modelReconciler
            super.init()
            self.transport.delegate = self
            dispatch_queue_set_specific(self.queuedEventsQueue, queuedEventsQueueSpecificKey, &queuedEventsQueueSpecificValue, nil)
        }
        
        /* Reconciler protocol implementation */
        public func reconcilerWillCreateEvent(reconciler: ModelReconciler) -> SeqPointer {
            return SeqPointer(precedingSeq: self.stream.latestSeq, clientSeq:self.stream.generateClientSeq())
        }
        
        public func reconciler(reconciler: ModelReconciler, didCreateEvent event: Sync.Event) {
            self.enqueue(event)
            self.publishEvents()
        }
        
        /* Transportable protocol implementation */
        public func transport(transport: Transport, didReceiveObject object: Serializable) {
            if let event = object as? Event {
                self.publishedEvents.append(event)
                self.modelReconciler.apply([event])
            } else if let stream = object as? Stream {
                self.stream.latestSeq = stream.latestSeq
            } else {
                // unsupported object
            }
        }
        
        public func transportDidConnect(transport: Transport) {
            self.publishEvents()
        }
        
        public func transportDidDisconnect(transport: Transport) {
            
        }
        
        /* Private methods */
        private func enqueue(event: Event) {
            dispatch_async(self.queuedEventsQueue) { () -> Void in
                self.collectionMutationGuard( { () -> Void in
                    self.queuedEvents = event.merge(self.queuedEvents)
                })
            }
        }
        
        /// A method that talks to the transport layer and in
        /// in charge of publishing the `Events` onto the network stream.
        private func publishEvents() {
            if !self.transport.isConnected {
                // Exit early, in case client doesn't have the connection
                // to the server.
                return
            }
            
            dispatch_async(self.queuedEventsQueue) { () -> Void in
                self.collectionMutationGuard( { () -> Void in
                    if self.queuedEvents.count == 0 {
                        // No events queued for publication
                        return
                    }
                    let eventPublicationRequest = EventPublicationRequest(events: self.queuedEvents)
                    let requestSemaphore = dispatch_semaphore_create(0)
                    var eventPublicationResponse: EventPublicationResponse?
                    self.transport.send(eventPublicationRequest) { (success: Bool, response: RPCObject?) -> Void in
                        if success {
                            eventPublicationResponse = response as! EventPublicationResponse?
                        }
                        dispatch_semaphore_signal(requestSemaphore)
                    }
                    dispatch_semaphore_wait(requestSemaphore, DISPATCH_TIME_FOREVER)

                    // Figure out, which events were successfully published, and
                    // evict them from the self.queuedEvents. Both collections
                    // (one we have locally and from response) should be of
                    // the same size.
                    if self.queuedEvents.count != eventPublicationResponse?.seqs.count {
                        return // failure
                    }
                    
                    // Assign just published event's.seq value received
                    // from response, and remove the event from the queue,
                    // so it doesn't get published twice.
                    for i in 0..<eventPublicationResponse!.seqs.count {
                        if eventPublicationResponse!.seqs[i] != EventPublicationResponse.EventNotFound {
                            let publishedEvent = self.queuedEvents[i]
                            // copy the sequence value from response
                            publishedEvent.seq = eventPublicationResponse!.seqs[i]
                            // put the event in publishedEvents
                            self.publishedEvents.append(publishedEvent)
                            // evict the event from the publication queue
                            self.queuedEvents.removeAtIndex(i)
                        }
                    }
                })
            }
        }
        
        private func collectionMutationGuard(mutationblock: dispatch_block_t) {
            if dispatch_queue_get_specific(self.queuedEventsQueue, self.queuedEventsQueueSpecificKey) == &self.queuedEventsQueueSpecificValue {
                mutationblock()
            } else {
                dispatch_sync(self.queuedEventsQueue, mutationblock)
            }
        }
    }
    
    public class Stream: NSObject, Serializable {
        /// Last known sequence value received from the server.
        public var _latestSeq: Int = 0
        public private(set) var clientSeq: Int = 0

        /// Instance variable indicating the connection state.
        public var latestSeq: Int {
            get {
                return self._latestSeq
            } set {
                self._latestSeq = newValue
                // resetting the client seq counter
                self.clientSeq = 0
            }
        }
        
        override init() {
            super.init()
            self.latestSeq = 0
        }

        public required init(fromDictionary dictionary: Dictionary<String, AnyObject>) {
            super.init()
            self.latestSeq = dictionary["latestSeq"] as! Int
        }
        
        public func toDictionary() -> Dictionary<String, AnyObject>
        {
            var dictionary: Dictionary<String, AnyObject> = Dictionary()
            dictionary["latestSeq"] = Int(self.latestSeq)
            return dictionary
        }
        
        internal func generateClientSeq() -> Int {
            return self.clientSeq++
        }
    }
    
    public struct SeqPointer {
        let precedingSeq: Int
        let clientSeq: Int
        init (precedingSeq: Int, clientSeq: Int) {
            self.precedingSeq = precedingSeq
            self.clientSeq = clientSeq
        }
    }
    
    public class Event: NSObject, Serializable {
        /**
         Event type describing a mutation on the model.
         */
        public enum Type: UInt8 {
            /// Adds a new object into the model.
            case Insert = 0
            
            /// Updates an existing object referenced by the `identifier`
            /// property with new values; values can be optional.
            case Update = 1
            
            /// Deletes an existing object from the model, referenced
            /// by the `identifier` property.
            case Delete = 2
        }
        
        /// Event sorting closure
        static public let causalOrder = { (e1: Event, e2: Event) -> Bool in
            if e1.precedingSeq == e2.precedingSeq {
                return e1.clientSeq < e2.clientSeq
            }
            return e1.precedingSeq < e2.precedingSeq
        }
        
        public private(set) var seq: Int?
        public private(set) var precedingSeq: Int
        public private(set) var clientSeq: Int
        public private(set) var type: Type
        public private(set) var identifier: NSUUID
        public private(set) var completed: Bool?
        public private(set) var title: String?
        public private(set) var label: UInt8?
        
        init(insert identifier: NSUUID, precedingSeq: Int, clientSeq: Int, completed: Bool, title: String, label: UInt8) {
            self.type = Type.Insert
            self.precedingSeq = precedingSeq
            self.clientSeq = clientSeq
            self.identifier = identifier
            self.completed = completed
            self.title = title
            self.label = label
        }
        
        init(update identifier: NSUUID, precedingSeq: Int, clientSeq: Int, completed: Bool?, title: String?, label: UInt8?) {
            self.type = Type.Update
            self.precedingSeq = precedingSeq
            self.clientSeq = clientSeq
            self.identifier = identifier
            self.completed = completed
            self.title = title
            self.label = label
        }
        
        init(delete identifier: NSUUID, precedingSeq: Int, clientSeq: Int) {
            self.type = Type.Delete
            self.identifier = identifier
            self.precedingSeq = precedingSeq
            self.clientSeq = clientSeq
        }
        
        public required init(fromDictionary dictionary: Dictionary<String, AnyObject>) {
            self.seq = dictionary["seq"] as! Int?
            self.precedingSeq = dictionary["precedingSeq"] as! Int
            self.clientSeq = dictionary["clientSeq"] as! Int
            self.type = Sync.Event.Type(rawValue: UInt8(dictionary["type"] as! Int))!
            self.identifier = NSUUID(UUIDString: dictionary["identifier"] as! String)!
            self.completed = dictionary["completed"] as! Bool?
            self.title = dictionary["title"] as! String?
            self.label = dictionary["label"] != nil ? UInt8((dictionary["label"] as! Int?)!) : nil
        }
        
        public func toDictionary() -> Dictionary<String, AnyObject>
        {
            var dictionary: Dictionary<String, AnyObject> = Dictionary()
            dictionary["type"] = Int(self.type.rawValue)
            dictionary["identifier"] = self.identifier.UUIDString
            dictionary["precedingSeq"] = self.precedingSeq
            dictionary["clientSeq"] = self.clientSeq
            if self.completed != nil {
                dictionary["completed"] = self.completed!
            }
            if self.title != nil {
                dictionary["title"] = self.title!
            }
            if self.label != nil {
                dictionary["label"] = Int(self.label!)
            }
            return dictionary
        }
        
        public func merge(events: Array<Event>) -> Array<Event> {
            var mergedEvents = Array<Event>()
            for oldEvent in events.sort(Event.causalOrder).reverse() {
                if oldEvent.identifier != self.identifier {
                    // Event not mergable, due to the identifier mismatch.
                    mergedEvents.append(oldEvent)
                    continue
                } else if self.type == Type.Delete {
                    // Rule #4
                    self.reset()
                    self.type = Type.Delete
                } else if self.type == Type.Update && (oldEvent.type == Type.Insert || oldEvent.type == Type.Update) {
                    // Rule #1, #2, #3
                    self.completed = self.completed ?? oldEvent.completed
                    self.title = self.title ?? oldEvent.title
                    self.label = self.label ?? oldEvent.label
                }
            }
            mergedEvents.append(self)
            return mergedEvents
        }
        
        private func reset() {
            self.seq = nil
            self.completed = nil
            self.title = nil
            self.label = nil
        }
    }
    
    public class EventInquiryRequest: RPCObject {
        public private(set) var seqs: Array<Int>
        
        init(seqs: Array<Int>) {
            self.seqs = seqs
            super.init(identifier: NSUUID())
        }
        
        public required init(fromDictionary dictionary: Dictionary<String, AnyObject>) {
            self.seqs = dictionary["seqs"] as! Array<Int>
            super.init(fromDictionary: dictionary)
        }
        
        public override func toDictionary() -> Dictionary<String, AnyObject> {
            var baseDictionary = super.toDictionary()
            baseDictionary["seqs"] = self.seqs
            return baseDictionary
        }
    }
    
    public class EventPublicationRequest: RPCObject {
        public private(set) var events: Array<Event>
        
        init(events: Array<Event>) {
            self.events = events
            super.init(identifier: NSUUID())
        }
        
        public required init(fromDictionary dictionary: Dictionary<String, AnyObject>) {
            self.events = Array<Event>()
            let dictionaryOfEvents = dictionary["events"] as! Array<Dictionary<String, AnyObject>>
            for serializedEvent in dictionaryOfEvents {
                let event = Event.init(fromDictionary: serializedEvent)
                self.events.append(event)
            }
            super.init(fromDictionary: dictionary)
        }
        
        public override func toDictionary() -> Dictionary<String, AnyObject> {
            var baseDictionary = super.toDictionary()
            var serializedEvents = Array<Dictionary<String, AnyObject>>()
            for event in self.events {
                serializedEvents.append(event.toDictionary())
            }
            baseDictionary["events"] = serializedEvents
            return baseDictionary
        }
    }
    
    public class EventPublicationResponse: RPCObject {
        public private(set) var seqs: Array<Int>
        public static let EventNotFound = Int(-1)
        
        public required init(fromDictionary dictionary: Dictionary<String, AnyObject>) {
            self.seqs = dictionary["seqs"] as! Array<Int>
            super.init(fromDictionary: dictionary)
        }
        
        public override func toDictionary() -> Dictionary<String, AnyObject> {
            var baseDictionary = super.toDictionary()
            baseDictionary["seqs"] = seqs
            return baseDictionary
        }
    }
}
