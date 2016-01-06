//
//  Sync.swift
//  example-02-todo-list
//
//  Created by Klemen Verdnik on 1/2/16.
//  Copyright © 2016 Klemen Verdnik. All rights reserved.
//

import Foundation

public protocol ModelReconciler: class {
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
    public class Stream: NSObject, OutboundEventReceiver {
        /// Last known sequence value received from the server.
        public private(set) var latestSeq: Int = 0
        
        /// Collection of all events known to client (sent and received).
        public private(set) var publishedEvents: Array<Event> = []
        
        /// Collection of all queued events meant for publication.
        /// This collection is drained as events get published.
        public private(set) var queuedEvents: Array<Event> = []
        
        public func reconciler(reconciler: ModelReconciler, didCreateEvent event: Sync.Event) {
            self.publish(event)
        }
        
        /// A method that talks to the transport layer and in
        /// in charge of publishing the `Events` onto the network stream.
        private func publish(event: Event) {
            // implement event publication logic here
        }
    }
    
    public class Event: NSObject {
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
        
        public private(set) var type: Type
        public private(set) var identifier: NSUUID
        public private(set) var completed: Bool?
        public private(set) var title: String?
        public private(set) var label: UInt8?
        
        init(insert identifier: NSUUID, completed: Bool, title: String, label: UInt8) {
            self.type = Type.Insert
            self.identifier = identifier
            self.completed = completed
            self.title = title
            self.label = label
        }
        
        init(update identifier: NSUUID, completed: Bool?, title: String?, label: UInt8?) {
            self.type = Type.Update
            self.identifier = identifier
            self.completed = completed
            self.title = title
            self.label = label
        }
        
        init(delete identifier: NSUUID) {
            self.type = Type.Delete
            self.identifier = identifier
        }
        
    }
}
