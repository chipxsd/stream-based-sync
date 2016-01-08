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
    }
    
    func testEventSerialization() {
        let identifier = NSUUID()
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

        let eventInsert = Sync.Event(insert: identifier, completed: false, title: "test", label: 83)
        let dictionaryFromEventInsert = eventInsert.toDictionary()
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
    
    func testStreamSerialization() {
        let streamFromDictionary = Sync.Stream.init(fromDictionary: [ "latestSeq": 83 ])
        expect(streamFromDictionary.latestSeq).to(equal(83))

        let stream = Sync.Stream.init()
        stream.latestSeq = 83
        let dictionaryFromStream = stream.toDictionary()
        expect(dictionaryFromStream["latestSeq"] as? Int).to(equal(83))
    }
    
    func testEventInquiryRequestInitialization() {
        let eventInquiryRequest = Sync.EventInquiryRequest(seqs: [1, 2, 3])
        expect(eventInquiryRequest.identifier).toNot(beNil())
        expect(eventInquiryRequest.seqs).to(equal([1, 2, 3]))
    }
    
    func testEventInquiryRequestSerialization() {
        let deserializedEventInquiryRequest = Sync.EventInquiryRequest(fromDictionary: [ "identifier": NSUUID().UUIDString, "seqs": [1, 2, 3] ])
        expect(deserializedEventInquiryRequest.identifier).toNot(beNil())
        expect(deserializedEventInquiryRequest.seqs).to(equal([1, 2, 3]))

        let eventInquiryRequest = Sync.EventInquiryRequest(seqs: [1, 2, 3])
        let dictonaryFromRequest: Dictionary<String, AnyObject> = eventInquiryRequest.toDictionary()
        expect(dictonaryFromRequest["identifier"] as? String).to(equal(eventInquiryRequest.identifier.UUIDString))
        expect(dictonaryFromRequest["seqs"] as? Array<Int>).to(equal([1, 2, 3]))
    }
    
    func testEventPublicationRequestInitialization() {
        let identifier = NSUUID()
        let eventInsert = Sync.Event(insert: identifier, completed: false, title: "test", label: 83)
        let eventPublicationRequest = Sync.EventPublicationRequest(events: [eventInsert])
        expect(eventPublicationRequest.identifier).toNot(beNil())
        expect(eventPublicationRequest.events).to(equal([eventInsert]))
    }
    
    func testEventPublicationRequestSerialization() {
        let identifier = NSUUID()
        let eventFromDictionary = Sync.EventPublicationRequest(fromDictionary: [
            "identifier": NSUUID().UUIDString,
            "events": [[
                "type": Int(Sync.Event.Type.Insert.rawValue),
                "identifier": identifier.UUIDString,
                "completed": false,
                "title": "test",
                "label": 83 ]
            ]])
        expect(eventFromDictionary.identifier).toNot(beNil())
        expect(eventFromDictionary.events[0].type).to(equal(Sync.Event.Type.Insert))
        expect(eventFromDictionary.events[0].identifier).to(equal(identifier))
        expect(eventFromDictionary.events[0].completed).to(equal(false))
        expect(eventFromDictionary.events[0].title).to(equal("test"))
        expect(eventFromDictionary.events[0].label).to(equal(83))
        
        let eventInsert = Sync.Event(insert: identifier, completed: false, title: "test", label: 83)
        let eventPublicationRequest = Sync.EventPublicationRequest(events: [eventInsert])
        let dictionaryFromRequest = eventPublicationRequest.toDictionary()
        expect(dictionaryFromRequest["identifier"] as? String).to(equal(eventPublicationRequest.identifier.UUIDString))
        let dictionaryOfEvents = dictionaryFromRequest["events"] as? Array<Dictionary<String, AnyObject>>
        expect(dictionaryOfEvents![0]["type"] as? Int).to(equal(0))
        expect(dictionaryOfEvents![0]["identifier"] as? String).to(equal(identifier.UUIDString))
        expect(dictionaryOfEvents![0]["completed"] as? Bool).to(equal(false))
        expect(dictionaryOfEvents![0]["title"] as? String).to(equal("test"))
        expect(dictionaryOfEvents![0]["label"] as? Int).to(equal(83))
    }
    
    func testEventPublicationResponseSerialization() {
        let identifier = NSUUID()
        let eventPublicationResponse = Sync.EventPublicationResponse(fromDictionary: [ "identifier": identifier.UUIDString, "seqs": [1, 2, 3]])
        expect(eventPublicationResponse.identifier).to(equal(identifier))
        expect(eventPublicationResponse.seqs).to(equal([1, 2, 3]))
        
        let eventPublicationDictionary = eventPublicationResponse.toDictionary()
        expect(eventPublicationDictionary["identifier"] as? String).to(equal(identifier.UUIDString))
        expect(eventPublicationDictionary["seqs"] as? Array<Int>).to(equal([1, 2, 3]))
    }
    
    func testClientInit() {
        let mockTransport = MockTransport(hostURL: NSURL(string: "ws://fakeurl")!, serializableClassRootKeys: [
            "event": Sync.Event.self,
            "stream": Sync.Stream.self,
            "event_inquiry_request": Sync.EventInquiryRequest.self,
            "event_publication_request": Sync.EventPublicationRequest.self,
            "event_publication_response": Sync.EventPublicationResponse.self])
        let mockModelReconciler = MockModelReconciler()
        let syncClient = Sync.Client(transport: mockTransport, modelReconciler: mockModelReconciler)
        expect(syncClient.modelReconciler === mockModelReconciler).to(beTrue())
        expect(syncClient.transport === mockTransport).to(beTrue())
        expect(syncClient.stream).toNot(beNil())
        expect(syncClient.stream.latestSeq).to(equal(0))
        expect(syncClient.publishedEvents).to(equal([]))
        expect(syncClient.queuedEvents).to(equal([]))
    }
    
    func testClientReceivingEvents() {
        let mockTransport = MockTransport(hostURL: NSURL(string: "ws://fakeurl")!, serializableClassRootKeys: [
            "event": Sync.Event.self,
            "stream": Sync.Stream.self,
            "event_inquiry_request": Sync.EventInquiryRequest.self,
            "event_publication_request": Sync.EventPublicationRequest.self,
            "event_publication_response": Sync.EventPublicationResponse.self])
        let mockModelReconciler = MockModelReconciler()
        let syncClient = Sync.Client(transport: mockTransport, modelReconciler: mockModelReconciler)
        expect(mockTransport.delegate === syncClient).to(beTrue())
        let identifier = NSUUID()
        
        // Connect and simulate a received event
        mockTransport.connect()
        mockTransport.mockWebSocketClient.mockReceivedText("{\n  \"event\" : {\n    \"title\" : \"test\",\n    \"completed\" : false,\n    \"label\" : 83,\n    \"identifier\" : \"\(identifier.UUIDString)\",\n    \"type\" : 0\n    \"tseq\" : 1337\n  }\n}")
        expect(mockModelReconciler.appliedEvents.count).toEventually(equal(1))
        expect(mockModelReconciler.appliedEvents[0].identifier).to(equal(identifier))
        expect(mockModelReconciler.appliedEvents[0].type).to(equal(Sync.Event.Type.Insert))
        expect(mockModelReconciler.appliedEvents[0].title).to(equal("test"))
        expect(mockModelReconciler.appliedEvents[0].completed).to(equal(false))
        expect(mockModelReconciler.appliedEvents[0].label).to(equal(83))
    }
    
    func testClientReceivingStream() {
        let mockTransport = MockTransport(hostURL: NSURL(string: "ws://fakeurl")!, serializableClassRootKeys: [
            "event": Sync.Event.self,
            "stream": Sync.Stream.self,
            "event_inquiry_request": Sync.EventInquiryRequest.self,
            "event_publication_request": Sync.EventPublicationRequest.self,
            "event_publication_response": Sync.EventPublicationResponse.self])
        let mockModelReconciler = MockModelReconciler()
        let syncClient = Sync.Client(transport: mockTransport, modelReconciler: mockModelReconciler)
        mockModelReconciler.outboundEventReceiver = syncClient
        expect(mockTransport.delegate === syncClient).to(beTrue())
        
        // Connect and simulate a received event
        mockTransport.connect()
        mockTransport.mockWebSocketClient.mockReceivedText("{\n  \"stream\" : {\n    \"latestSeq\" : 1337\n  }\n}")
        expect(syncClient.stream.latestSeq).toEventually(equal(1337))
    }
    
    func testClientEventQueueingWhenDisconnected() {
        let mockTransport = MockTransport(hostURL: NSURL(string: "ws://fakeurl")!, serializableClassRootKeys: [
            "event": Sync.Event.self,
            "stream": Sync.Stream.self,
            "event_inquiry_request": Sync.EventInquiryRequest.self,
            "event_publication_request": Sync.EventPublicationRequest.self,
            "event_publication_response": Sync.EventPublicationResponse.self])
        let mockModelReconciler = MockModelReconciler()
        let syncClient = Sync.Client(transport: mockTransport, modelReconciler: mockModelReconciler)
        mockModelReconciler.outboundEventReceiver = syncClient
        expect(mockTransport.delegate === syncClient).to(beTrue())
        
        // Connect and simulate a received event
        mockTransport.disconnect()
        let identifier = NSUUID()
        let eventInsert = Sync.Event(insert: identifier, completed: false, title: "test", label: 83)
        mockModelReconciler.mockDidCreateEvent(eventInsert)
        
        expect(syncClient.queuedEvents.count).toEventually(equal(1))
        expect(syncClient.queuedEvents[0]).to(equal(eventInsert))
    }
}
