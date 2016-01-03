//
//  TodoList.swift
//  example-02-todo-list
//
//  Created by Klemen Verdnik on 1/2/16.
//  Copyright © 2016 Klemen Verdnik. All rights reserved.
//

import Foundation

public struct Todo {

    public class List: NSObject {

        /// Private collection of tasks maintained by this class.
        private let tasks: Array<Task> = []
        
        /**
         Creates a new `Task` instance and adds it to the end of the list.
         
         - parameter title: Task title.
         - parameter label: Task color coded label.
         */
        public func create(title: String, label: Task.ColorLabel) {

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
         */
        public func update(identifier: NSUUID, completed: Bool?, title: String?, label: Task.ColorLabel?) {
            
        }

        /**
         Removes an existing task from the list based on the given identifier.
         
         - parameter identifier: Task indentifier used to locate and delete
                                 the task from the list.
         */
        public func remove(identifier: NSUUID) {
            
        }
        
    }

    public class Task: NSObject {
        
        /// Client generated identifier, used for de-duplication.
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
        
    }
    
}