//
//  TodoListTests.swift
//  example-02-todo-list
//
//  Created by Klemen Verdnik on 1/4/16.
//  Copyright © 2016 Klemen Verdnik. All rights reserved.
//

import XCTest
import Nimble

class TodoListTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTodoTaskInitialization() {
        let identifier = NSUUID()
        let todoTask = Todo.Task(identifier: identifier, completed: false, title: "Get milk", label: Todo.Task.ColorLabel.Blue)
        expect(todoTask.identifier).to(equal(identifier))
        expect(todoTask.completed).to(beFalse())
        expect(todoTask.title).to(equal("Get milk"))
        expect(todoTask.label).to(equal(Todo.Task.ColorLabel.Blue))
    }

    func testTodoTaskUpdate() {
        let identifier = NSUUID()
        let todoTask = Todo.Task(identifier: identifier, completed: false, title: "Get milk", label: Todo.Task.ColorLabel.Blue)
        todoTask.update(true, title: nil, label: nil)
        expect(todoTask.identifier).to(equal(identifier))
        expect(todoTask.completed).to(beTrue())
        expect(todoTask.title).to(equal("Get milk"))
        expect(todoTask.label).to(equal(Todo.Task.ColorLabel.Blue))
        
        todoTask.update(nil, title: "Get cocoa", label: nil)
        expect(todoTask.identifier).to(equal(identifier))
        expect(todoTask.completed).to(beTrue())
        expect(todoTask.title).to(equal("Get cocoa"))
        expect(todoTask.label).to(equal(Todo.Task.ColorLabel.Blue))

        todoTask.update(nil, title: nil, label: Todo.Task.ColorLabel.Pink)
        expect(todoTask.identifier).to(equal(identifier))
        expect(todoTask.completed).to(beTrue())
        expect(todoTask.title).to(equal("Get cocoa"))
        expect(todoTask.label).to(equal(Todo.Task.ColorLabel.Pink))
    }

    func testTodoListCreateCreatesEventAndTask() {
        let todoList = Todo.List()
        let mockOutboundReconciler = MockOutboundReconciler(modelReconciler: todoList)
        todoList.outboundEventReceiver = mockOutboundReconciler
        mockOutboundReconciler.mockSeqPointer = Sync.SeqPointer(precedingSeq: 10, clientSeq: 20)
        
        // invoking user-action
        todoList.create("Buy Milk", label: Todo.Task.ColorLabel.Blue)
        expect(mockOutboundReconciler.createdEvents.count).to(equal(1))
        expect(todoList.tasks.count).to(equal(1))

        // extracting artifacts
        let createdTask = todoList.tasks[0]
        let createdEvent = mockOutboundReconciler.createdEvents[0]
        
        // verifying generated events
        expect(createdEvent.type).to(equal(Sync.Event.Type.Insert))
        expect(createdEvent.identifier).to(equal(createdTask.identifier))
        expect(createdEvent.precedingSeq).to(equal(10))
        expect(createdEvent.clientSeq).to(equal(20))
        expect(createdEvent.title).to(equal("Buy Milk"))
        expect(createdEvent.completed).to(beFalse())
        expect(createdEvent.label).to(equal(Todo.Task.ColorLabel.Blue.rawValue))

        // verifying model
        expect(createdTask.title).to(equal("Buy Milk"))
        expect(createdTask.label).to(equal(Todo.Task.ColorLabel.Blue))
        expect(createdTask.completed).to(beFalse())
    }
    
    func testTodoListUpdateCreatesEventAndUpdatesTask() {
        let todoList = Todo.List()
        let mockOutboundReconciler = MockOutboundReconciler(modelReconciler: todoList)
        todoList.outboundEventReceiver = mockOutboundReconciler
        mockOutboundReconciler.mockSeqPointer = Sync.SeqPointer(precedingSeq: 10, clientSeq: 20)

        todoList.create("Buy Milk", label: Todo.Task.ColorLabel.Blue)
        expect(mockOutboundReconciler.createdEvents.count).to(equal(1))
        expect(todoList.tasks.count).to(equal(1))
        
        let createdTask = todoList.tasks[0]
  
        // invoking user-action
        todoList.update(createdTask.identifier, completed: true, title: nil, label: nil)
        expect(mockOutboundReconciler.createdEvents.count).to(equal(2))
        expect(todoList.tasks.count).to(equal(1))
        
        // extracting artifacts
        let createdEvent = mockOutboundReconciler.createdEvents[1]
        
        // verifying last generated event
        expect(createdEvent.type).to(equal(Sync.Event.Type.Update))
        expect(createdEvent.identifier).to(equal(createdTask.identifier))
        expect(createdEvent.precedingSeq).to(equal(10))
        expect(createdEvent.clientSeq).to(equal(20))
        expect(createdEvent.title).to(beNil())
        expect(createdEvent.completed).to(beTrue())
        expect(createdEvent.label).to(beNil())
        
        // verifying model
        expect(createdTask.title).to(equal("Buy Milk"))
        expect(createdTask.label).to(equal(Todo.Task.ColorLabel.Blue))
        expect(createdTask.completed).to(beTrue())
    }
    
    func testTodoListDeleteCreatesEventAndDeletesTask() {
        let todoList = Todo.List()
        let mockOutboundReconciler = MockOutboundReconciler(modelReconciler: todoList)
        todoList.outboundEventReceiver = mockOutboundReconciler
        mockOutboundReconciler.mockSeqPointer = Sync.SeqPointer(precedingSeq: 10, clientSeq: 20)
        
        todoList.create("Buy Milk", label: Todo.Task.ColorLabel.Blue)
        expect(mockOutboundReconciler.createdEvents.count).to(equal(1))
        expect(todoList.tasks.count).to(equal(1))
        
        let createdTask = todoList.tasks[0]
        
        // invoking user-action
        todoList.remove(createdTask.identifier)
        expect(mockOutboundReconciler.createdEvents.count).to(equal(2))
        expect(todoList.tasks.count).to(equal(0))
        
        // extracting artifacts
        let createdEvent = mockOutboundReconciler.createdEvents[1]
        
        // verifying last generated event
        expect(createdEvent.type).to(equal(Sync.Event.Type.Delete))
        expect(createdEvent.identifier).to(equal(createdTask.identifier))
        expect(createdEvent.precedingSeq).to(equal(10))
        expect(createdEvent.clientSeq).to(equal(20))
        expect(createdEvent.title).to(beNil())
        expect(createdEvent.completed).to(beNil())
        expect(createdEvent.label).to(beNil())
    }
    
    func testTodoListApplyEventsInCausalOrder() {
        let identifierA = NSUUID()
        let identifierB = NSUUID()
        let todoList = Todo.List()
        let events = [
            Sync.Event(insert: identifierA, precedingSeq: 0, clientSeq: 1, completed: false, title: "Buy Mil", label: 0),
            Sync.Event(update: identifierA, precedingSeq: 0, clientSeq: 2, completed: nil, title: "Buy Milk", label: nil),
            Sync.Event(update: identifierB, precedingSeq: 3, clientSeq: 0, completed: true, title: nil, label: nil),
            Sync.Event(update: identifierB, precedingSeq: 2, clientSeq: 0, completed: nil, title: "Get a lot of Beer", label: nil),
            Sync.Event(insert: identifierB, precedingSeq: 1, clientSeq: 0, completed: false, title: "Get Beer", label: 2),
            Sync.Event(update: identifierA, precedingSeq: 1, clientSeq: 1, completed: true, title: nil, label: nil)
        ]
        // fill er up
        todoList.apply(events)
        
        // verify model
        expect(todoList.tasks.count).to(equal(2))
        
        // verify final model state
        let taskA = todoList.tasks[0]
        expect(taskA.identifier).to(equal(identifierA))
        expect(taskA.title).to(equal("Buy Milk"))
        expect(taskA.completed).to(beTrue())
        expect(taskA.label).to(equal(Todo.Task.ColorLabel.None))
        
        let taskB = todoList.tasks[1]
        expect(taskB.identifier).to(equal(identifierB))
        expect(taskB.title).to(equal("Get a lot of Beer"))
        expect(taskB.completed).to(beTrue())
        expect(taskB.label).to(equal(Todo.Task.ColorLabel.Orange))
    }
}
