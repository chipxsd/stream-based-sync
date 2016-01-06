//
//  SyncTests.swift
//  example-02-todo-list
//
//  Created by Klemen Verdnik on 1/5/16.
//  Copyright © 2016 Klemen Verdnik. All rights reserved.
//

import XCTest
import Nimble

class SyncTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testEventInitialization() {
        let identifier = NSUUID()
        let eventInsert = Sync.Event(insert: identifier, completed: false, title: "test", label: 83)
        expect(eventInsert.type).to(equal(Sync.Event.Type.Insert))
        expect(eventInsert.identifier).to(equal(identifier))
        expect(eventInsert.completed).to(beFalse())
        expect(eventInsert.title).to(equal("test"))
        expect(eventInsert.label).to(equal(83))
        
        let eventUpdate = Sync.Event(update: identifier, completed: false, title: "test", label: 83)
        expect(eventUpdate.type).to(equal(Sync.Event.Type.Update))
        expect(eventUpdate.identifier).to(equal(identifier))
        expect(eventUpdate.completed).to(beFalse())
        expect(eventUpdate.title).to(equal("test"))
        expect(eventUpdate.label).to(equal(83))
        
        let eventDelete = Sync.Event(delete: identifier)
        expect(eventDelete.type).to(equal(Sync.Event.Type.Delete))
        expect(eventDelete.identifier).to(equal(identifier))
        expect(eventDelete.completed).to(beNil())
        expect(eventDelete.title).to(beNil())
        expect(eventDelete.label).to(beNil())

        let eventFromDictionaryInsert = Sync.Event(fromDictionary: [
            "type": Int(Sync.Event.Type.Insert.rawValue),
            "identifier": identifier.UUIDString,
            "completed": false,
            "title": "test",
            "label": 83 ])
        expect(eventFromDictionaryInsert.type).to(equal(Sync.Event.Type.Insert))
        expect(eventFromDictionaryInsert.identifier).to(equal(identifier))
        expect(eventFromDictionaryInsert.completed).to(beFalse())
        expect(eventFromDictionaryInsert.title).to(equal("test"))
        expect(eventFromDictionaryInsert.label).to(equal(83))
        
        let eventFromDictionaryDelete = Sync.Event(fromDictionary: [
            "type": Int(Sync.Event.Type.Delete.rawValue),
            "identifier": identifier.UUIDString ])
        expect(eventFromDictionaryDelete.type).to(equal(Sync.Event.Type.Delete))
        expect(eventFromDictionaryDelete.identifier).to(equal(identifier))
        expect(eventFromDictionaryDelete.completed).to(beNil())
        expect(eventFromDictionaryDelete.title).to(beNil())
        expect(eventFromDictionaryDelete.label).to(beNil())
    }
    
    func testEventToDictionary() {
        let identifier = NSUUID()
        let eventInsert = Sync.Event(insert: identifier, completed: false, title: "test", label: 83)
        let dictionaryFromEventInsert = eventInsert.toDictionary()
//        expect(dictionaryFromEvent["type"]).toNot(beNil())
//        expect(dictionaryFromEvent["identifier"]).toNot(beNil())
//        expect(dictionaryFromEvent["completed"]).toNot(beNil())
//        expect(dictionaryFromEvent["title"]).toNot(beNil())
//        expect(dictionaryFromEvent["label"]).toNot(beNil())
        
        expect(dictionaryFromEventInsert["type"] as? Int).to(equal(0))
        expect(dictionaryFromEventInsert["identifier"] as? String).to(equal(identifier.UUIDString))
        expect(dictionaryFromEventInsert["completed"] as? Bool).to(equal(false))
        expect(dictionaryFromEventInsert["title"] as? String).to(equal("test"))
        expect(dictionaryFromEventInsert["label"] as? Int).to(equal(83))
        
        let eventDelete = Sync.Event(delete: identifier)
        let dictionaryFromEventDelete = eventDelete.toDictionary()
        expect(dictionaryFromEventDelete["type"] as? Int).to(equal(2))
        expect(dictionaryFromEventDelete["identifier"] as? String).to(equal(identifier.UUIDString))
        expect(dictionaryFromEventDelete["completed"] as? Bool).to(beNil())
        expect(dictionaryFromEventDelete["title"] as? String).to(beNil())
        expect(dictionaryFromEventDelete["label"] as? Int).to(beNil())
    }
}
