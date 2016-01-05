//
//  Sync.swift
//  example-02-todo-list
//
//  Created by Klemen Verdnik on 1/2/16.
//  Copyright © 2016 Klemen Verdnik. All rights reserved.
//

import Foundation

public struct Sync {

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
        public private(set) var identifier: NSUUID?
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
    
    public class Stream: NSObject {
        
        /// Last known sequence value received from the server.
        public private(set) var latestSeq: Int = 0
        
        /// Collection of all events known to client (sent and received).
        public private(set) var publishedEvents: Array<Event> = []
        
        /// Collection of all queued events meant for publication.
        /// This collection is drained as events get published.
        public private(set) var queuedEvents: Array<Event> = []
        
        /// A method that talks to the transport layer and in
        /// in charge of publishing the `Events` onto the network stream.
        public func publish(event: Event) {
            
        }
        
    }

}
