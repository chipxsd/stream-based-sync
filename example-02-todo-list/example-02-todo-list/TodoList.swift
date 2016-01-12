//
//  TodoList.swift
//  example-02-todo-list
//
//  Created by Klemen Verdnik on 1/2/16.
//  Copyright © 2016 Klemen Verdnik. All rights reserved.
//

import Foundation

public struct Todo {
    public class List: NSObject, ModelReconciler {
        /// Private collection of tasks maintained by this class.
        internal var tasks: Array<Task> = []
        
        /// Delegate that's in charge of event publication.
        public weak var outboundEventReceiver: OutboundEventReceiver?
        
        /**
         Creates a new `Task` instance and adds it to the end of the list.
         
         - parameter title: Task title.
         - parameter label: Task color coded label.
         
         - returns: An `Event` describing the creation of a new object.
         */
        public func create(title: String, label: Task.ColorLabel) -> Bool {
            let seqPointer = self.outboundEventReceiver?.reconcilerWillCreateEvent(self)
            let event = Sync.Event(insert: NSUUID(), precedingSeq: (seqPointer?.precedingSeq)!, clientSeq: (seqPointer?.clientSeq)!, completed: false, title: title, label: label.rawValue)
            return self.applyAndNotify(event)
        }
        
        /**
         Updates an existing task with given optional values based on the
         task identifier.
         
         - parameter identifier: Task identifier used to locate the task that
                                 should be updated.
         - parameter completed:  If set, the task will be updated with the
                                 given completion state, which can be either
                                 `true` or `false`.
         - parameter title:      If set, the task will be updated with the
                                 new given title.
         - parameter label:      If set, the task will be updated with the
                                 new color label.

         - returns: An `Event` describing the mutation of an object.
         */
        public func update(identifier: NSUUID, completed: Bool?, title: String?, label: Task.ColorLabel?) -> Bool {
            let seqPointer = self.outboundEventReceiver?.reconcilerWillCreateEvent(self)
            let event = Sync.Event(update: identifier, precedingSeq: (seqPointer?.precedingSeq)!, clientSeq: (seqPointer?.clientSeq)!, completed: completed, title: title, label: label != nil ? label!.rawValue : nil as UInt8?)
            return self.applyAndNotify(event)
        }

        /**
         Removes an existing task from the list based on the given identifier.
         
         - parameter identifier: Task indentifier used to locate and delete
                                 the task from the list.
         
         - returns: An `Event` describing the deletion of an object.
         */
        public func remove(identifier: NSUUID) -> Bool {
            let seqPointer = self.outboundEventReceiver?.reconcilerWillCreateEvent(self)
            let event = Sync.Event(delete: identifier, precedingSeq: (seqPointer?.precedingSeq)!, clientSeq: (seqPointer?.clientSeq)!)
            return self.applyAndNotify(event)
        }
        
        public func apply(events: Array<Sync.Event>) -> Bool {
            for event in events.sort(Sync.Event.causalOrder) {
                let success = self.apply(event)
                if !success {
                    return false
                }
            }
            return true
        }
        
        /**
         Applies a synced Event onto the List model.
         
         - parameter event: A synced event to apply on the model.
         
         - returns: Returns `true`, if the operation was successful;
         in case of a conflict, the method returns `false`.
         */
        private func apply(event: Sync.Event) -> Bool {
            switch event.type {
            case .Insert: // Task creation
                let task = Task(identifier: event.identifier, completed: event.completed!, title: event.title!, label: Task.ColorLabel(rawValue: event.label!)!)
                self.tasks.append(task)
            case .Update: // Task updates
                let task = self.task(event.identifier)
                if task == nil {
                    return false
                }
                task!.update(event.completed, title: event.title, label: event.label != nil ? Task.ColorLabel(rawValue: event.label!) : nil)
            case .Delete: // Task removal
                if !self.removeTask(event.identifier) {
                    return false
                }
            }
            return true
        }
        
        private func applyAndNotify(event: Sync.Event) -> Bool {
            if self.apply(event) {
                self.outboundEventReceiver?.reconciler(self, didCreateEvent: event)
                return true
            }
            return false
        }
        
        private func indexOfTask(identifier: NSUUID) -> Array<Task>.Index? {
            return self.tasks.indexOf({ $0.identifier == identifier })
        }
        
        private func task(identifier: NSUUID) -> Task? {
            let indexOfTask = self.indexOfTask(identifier)
            if indexOfTask == nil {
                return nil
            }
            return self.tasks[indexOfTask!]
        }
        
        private func removeTask(identifier: NSUUID) -> Bool {
            let indexOfTask = self.indexOfTask(identifier)
            if indexOfTask == nil {
                return false
            }
            self.tasks.removeAtIndex(indexOfTask!)
            return true
        }
        
    }

    public class Task: NSObject {
        /// Client generated identifier, used for referencing and de-duplication.
        public private(set) var identifier: NSUUID
        
        /// Boolean state indicating the completion of the task.
        public private(set) var completed: Bool
        
        /// Text description of the task.
        public private(set) var title: String
        
        /// Color coded label of the task.
        public private(set) var label: ColorLabel
        
        public enum ColorLabel: UInt8 {
            case None = 0, Red, Orange, Yellow, Green, Turquoise, Blue, Purple, Pink
        }
        
        init(identifier: NSUUID, completed: Bool, title: String, label: ColorLabel) {
            self.identifier = identifier
            self.completed = completed
            self.title = title
            self.label = label
        }
        
        public func update(completed: Bool?, title: String?, label: Task.ColorLabel?) {
            if completed != nil {
                self.completed = completed!
            }
            if title != nil {
                self.title = title!
            }
            if label != nil {
                self.label = label!
            }
        }
        
        public override var description: String {
            return "<Todo.Task: \(unsafeAddressOf(self)) identifier=\(self.identifier.UUIDString) completed=\(self.completed) title=\"\(self.title)\" label=\(self.label)>"
        }
    }
}