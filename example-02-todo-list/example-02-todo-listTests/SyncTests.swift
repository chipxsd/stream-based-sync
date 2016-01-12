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
        let eventInsert = Sync.Event(insert: identifier, precedingSeq: 10, clientSeq: 20, completed: false, title: "test", label: 83)
        expect(eventInsert.type).to(equal(Sync.Event.Type.Insert))
        expect(eventInsert.precedingSeq).to(equal(10))
        expect(eventInsert.clientSeq).to(equal(20))
        expect(eventInsert.identifier).to(equal(identifier))
        expect(eventInsert.completed).to(beFalse())
        expect(eventInsert.title).to(equal("test"))
        expect(eventInsert.label).to(equal(83))
        
        let eventUpdate = Sync.Event(update: identifier, precedingSeq: 10, clientSeq: 20, completed: false, title: "test", label: 83)
        expect(eventUpdate.type).to(equal(Sync.Event.Type.Update))
        expect(eventInsert.precedingSeq).to(equal(10))
        expect(eventInsert.clientSeq).to(equal(20))
        expect(eventUpdate.identifier).to(equal(identifier))
        expect(eventUpdate.completed).to(beFalse())
        expect(eventUpdate.title).to(equal("test"))
        expect(eventUpdate.label).to(equal(83))
        
        let eventDelete = Sync.Event(delete: identifier, precedingSeq: 10, clientSeq: 20)
        expect(eventDelete.type).to(equal(Sync.Event.Type.Delete))
        expect(eventInsert.precedingSeq).to(equal(10))
        expect(eventInsert.clientSeq).to(equal(20))
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
            "precedingSeq": 10,
            "clientSeq": 20,
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
            "identifier": identifier.UUIDString,
            "precedingSeq": 10,
            "clientSeq": 20 ])
        expect(eventFromDictionaryDelete.type).to(equal(Sync.Event.Type.Delete))
        expect(eventFromDictionaryDelete.identifier).to(equal(identifier))
        expect(eventFromDictionaryDelete.completed).to(beNil())
        expect(eventFromDictionaryDelete.title).to(beNil())
        expect(eventFromDictionaryDelete.label).to(beNil())

        let eventInsert = Sync.Event(insert: identifier, precedingSeq: 10, clientSeq: 20, completed: false, title: "test", label: 83)
        let dictionaryFromEventInsert = eventInsert.toDictionary()
        expect(dictionaryFromEventInsert["type"] as? Int).to(equal(0))
        expect(dictionaryFromEventInsert["identifier"] as? String).to(equal(identifier.UUIDString))
        expect(dictionaryFromEventInsert["precedingSeq"] as? Int).to(equal(10))
        expect(dictionaryFromEventInsert["clientSeq"] as? Int).to(equal(20))
        expect(dictionaryFromEventInsert["completed"] as? Bool).to(equal(false))
        expect(dictionaryFromEventInsert["title"] as? String).to(equal("test"))
        expect(dictionaryFromEventInsert["label"] as? Int).to(equal(83))
        
        let eventDelete = Sync.Event(delete: identifier, precedingSeq: 10, clientSeq: 20)
        let dictionaryFromEventDelete = eventDelete.toDictionary()
        expect(dictionaryFromEventDelete["type"] as? Int).to(equal(2))
        expect(dictionaryFromEventDelete["identifier"] as? String).to(equal(identifier.UUIDString))
        expect(dictionaryFromEventInsert["precedingSeq"] as? Int).to(equal(10))
        expect(dictionaryFromEventInsert["clientSeq"] as? Int).to(equal(20))
        expect(dictionaryFromEventDelete["completed"] as? Bool).to(beNil())
        expect(dictionaryFromEventDelete["title"] as? String).to(beNil())
        expect(dictionaryFromEventDelete["label"] as? Int).to(beNil())
    }
    
    func testEventMergeMismatchedIdentifiersIgnored() {
        var queuedEvents = Array<Sync.Event>()
        queuedEvents.append(Sync.Event(insert: NSUUID(), precedingSeq: 10, clientSeq: 20, completed: true, title: "buy milk", label: 1))
        queuedEvents.append(Sync.Event(update: NSUUID(), precedingSeq: 10, clientSeq: 21, completed: false, title: "buy cookies", label: 3))
        queuedEvents.append(Sync.Event(delete: NSUUID(), precedingSeq: 10, clientSeq: 22))
        
        let identifier = NSUUID()
        let lastEvent = Sync.Event(update: identifier, precedingSeq: 10, clientSeq: 23, completed: nil, title: nil, label: nil)
        let mergedEvents = lastEvent.merge(queuedEvents)
        expect(mergedEvents.count).to(equal(4))
        
        expect(lastEvent.identifier).to(equal(identifier))
        expect(lastEvent.type).to(equal(Sync.Event.Type.Update))
        expect(lastEvent.completed).to(beNil())
        expect(lastEvent.title).to(beNil())
        expect(lastEvent.label).to(beNil())
    }
    
    func testEventMergeUpdatesCoalescedAndLastWins() {
        let identifier = NSUUID()
        var queuedEvents = Array<Sync.Event>()
        queuedEvents.append(Sync.Event(insert: identifier, precedingSeq: 10, clientSeq: 20, completed: false, title: "buy milk", label: 1))
        queuedEvents.append(Sync.Event(update: identifier, precedingSeq: 11, clientSeq: 21, completed: nil, title: "no, buy cookies", label: nil))
        queuedEvents.append(Sync.Event(update: identifier, precedingSeq: 12, clientSeq: 22, completed: nil, title: nil, label: 3))
        
        let lastEvent = Sync.Event(update: identifier, precedingSeq: 10, clientSeq: 23, completed: true, title: nil, label: nil)
        let mergedEvents = lastEvent.merge(queuedEvents)
        expect(mergedEvents.count).to(equal(1))
        
        expect(lastEvent.identifier).to(equal(identifier))
        expect(lastEvent.type).to(equal(Sync.Event.Type.Update))
        expect(lastEvent.completed).to(equal(true))
        expect(lastEvent.title).to(equal("no, buy cookies"))
        expect(lastEvent.label).to(equal(3))
    }
    
    func testEventMergeDeleteClobersOtherUpdates() {
        let identifier = NSUUID()
        var queuedEvents = Array<Sync.Event>()
        queuedEvents.append(Sync.Event(insert: identifier, precedingSeq: 10, clientSeq: 20, completed: false, title: "buy milk", label: 1))
        queuedEvents.append(Sync.Event(update: identifier, precedingSeq: 10, clientSeq: 21, completed: nil, title: "no, buy cookies", label: nil))
        queuedEvents.append(Sync.Event(update: identifier, precedingSeq: 10, clientSeq: 22, completed: nil, title: nil, label: 3))
        
        let lastEvent = Sync.Event(delete: identifier, precedingSeq: 10, clientSeq: 20)
        let mergedEvents = lastEvent.merge(queuedEvents)
        expect(mergedEvents.count).to(equal(1))
        
        expect(lastEvent.identifier).to(equal(identifier))
        expect(lastEvent.type).to(equal(Sync.Event.Type.Delete))
        expect(lastEvent.completed).to(beNil())
        expect(lastEvent.title).to(beNil())
        expect(lastEvent.label).to(beNil())
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
        let eventInsert = Sync.Event(insert: identifier, precedingSeq: 10, clientSeq: 20, completed: false, title: "test", label: 83)
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
                "precedingSeq": 10,
                "clientSeq": 20,
                "completed": false,
                "title": "test",
                "label": 83 ]
            ]])
        expect(eventFromDictionary.identifier).toNot(beNil())
        expect(eventFromDictionary.events[0].type).to(equal(Sync.Event.Type.Insert))
        expect(eventFromDictionary.events[0].identifier).to(equal(identifier))
        expect(eventFromDictionary.events[0].precedingSeq).to(equal(10))
        expect(eventFromDictionary.events[0].clientSeq).to(equal(20))
        expect(eventFromDictionary.events[0].completed).to(equal(false))
        expect(eventFromDictionary.events[0].title).to(equal("test"))
        expect(eventFromDictionary.events[0].label).to(equal(83))
        
        let eventInsert = Sync.Event(insert: identifier, precedingSeq: 10, clientSeq: 20, completed: false, title: "test", label: 83)
        let eventPublicationRequest = Sync.EventPublicationRequest(events: [eventInsert])
        let dictionaryFromRequest = eventPublicationRequest.toDictionary()
        expect(dictionaryFromRequest["identifier"] as? String).to(equal(eventPublicationRequest.identifier.UUIDString))
        let dictionaryOfEvents = dictionaryFromRequest["events"] as? Array<Dictionary<String, AnyObject>>
        expect(dictionaryOfEvents![0]["type"] as? Int).to(equal(0))
        expect(dictionaryOfEvents![0]["identifier"] as? String).to(equal(identifier.UUIDString))
        expect(dictionaryOfEvents![0]["precedingSeq"] as? Int).to(equal(10))
        expect(dictionaryOfEvents![0]["clientSeq"] as? Int).to(equal(20))
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
        mockTransport.mockWebSocketClient.mockReceivedText("{\n  \"event\" : {\n    \"title\" : \"test\",\n    \"completed\" : false,\n    \"label\" : 83,\n    \"identifier\" : \"\(identifier.UUIDString)\",\n    \"type\" : 0,\n    \"seq\" : 1337,\n    \"precedingSeq\" : 10,    \"clientSeq\" : 20 }\n}")
        expect(mockModelReconciler.appliedEvents.count).toEventually(equal(1))
        expect(mockModelReconciler.appliedEvents[0].identifier).to(equal(identifier))
        expect(mockModelReconciler.appliedEvents[0].type).to(equal(Sync.Event.Type.Insert))
        expect(mockModelReconciler.appliedEvents[0].title).to(equal("test"))
        expect(mockModelReconciler.appliedEvents[0].completed).to(equal(false))
        expect(mockModelReconciler.appliedEvents[0].label).to(equal(83))
        expect(mockModelReconciler.appliedEvents[0].seq).to(equal(1337))
        expect(mockModelReconciler.appliedEvents[0].precedingSeq).to(equal(10))
        expect(mockModelReconciler.appliedEvents[0].clientSeq).to(equal(20))
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
        let eventInsert = Sync.Event(insert: identifier, precedingSeq: 10, clientSeq: 20, completed: false, title: "test", label: 83)
        mockModelReconciler.mockDidCreateEvent(eventInsert)
        
        expect(syncClient.queuedEvents.count).toEventually(equal(1))
        expect(syncClient.queuedEvents[0]).to(equal(eventInsert))
    }
    
    func testClientEventPublicationWhenConnected() {
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
        let identifier = NSUUID()
        let eventInsert = Sync.Event(insert: identifier, precedingSeq: 10, clientSeq: 20, completed: false, title: "test", label: 83)
        mockModelReconciler.mockDidCreateEvent(eventInsert)
        
        // Event queued
        expect(syncClient.queuedEvents.count).toEventually(equal(1))
        expect(syncClient.queuedEvents[0]).to(equal(eventInsert))
        expect(syncClient.publishedEvents.count).to(equal(0))
        
        // Request sent
        expect(mockTransport.mockWebSocketClient.sentText.count).toEventually(equal(1))

        // Simulate a response
        let sentRequestJSONString = mockTransport.mockWebSocketClient.sentText[0]
        let JSONData = sentRequestJSONString.dataUsingEncoding(NSUTF8StringEncoding)
        let requestDictionary = try! NSJSONSerialization.JSONObjectWithData(JSONData!, options: NSJSONReadingOptions.AllowFragments) as? Dictionary<String, AnyObject>
        mockTransport.mockWebSocketClient.mockReceivedText("{\"event_publication_response\":{\"identifier\":\"\(requestDictionary!["event_publication_request"]!["identifier"])\", \"seqs\":[1337]}}")
        
        // Queue drained (due to async publishing behavior)
        expect(syncClient.queuedEvents.count).toEventually(equal(0))
        expect(syncClient.publishedEvents.count).to(equal(1))
        
        // Verify if the response took care of the event
        let publishedEvent = syncClient.publishedEvents[0]
        expect(publishedEvent.seq).to(equal(1337))
    }
    
    func testClientEventQueueingAndPublicationWhenTransitioningOnline() {
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
        let eventInsert = Sync.Event(insert: identifier, precedingSeq: 10, clientSeq: 20, completed: false, title: "test", label: 83)
        mockModelReconciler.mockDidCreateEvent(eventInsert)
        
        // Event queued
        expect(syncClient.queuedEvents.count).toEventually(equal(1))
        expect(syncClient.queuedEvents[0]).to(equal(eventInsert))
        expect(syncClient.publishedEvents.count).to(equal(0))
        
        // Request should not be sent yet
        expect(mockTransport.mockWebSocketClient.sentText.count).toEventually(equal(0))
        
        // Connect the client
        mockTransport.connect()
        
        // Request sent
        expect(mockTransport.mockWebSocketClient.sentText.count).toEventually(equal(1))
        
        // Simulate a response
        let sentRequestJSONString = mockTransport.mockWebSocketClient.sentText[0]
        let JSONData = sentRequestJSONString.dataUsingEncoding(NSUTF8StringEncoding)
        let requestDictionary = try! NSJSONSerialization.JSONObjectWithData(JSONData!, options: NSJSONReadingOptions.AllowFragments) as? Dictionary<String, AnyObject>
        mockTransport.mockWebSocketClient.mockReceivedText("{\"event_publication_response\":{\"identifier\":\"\(requestDictionary!["event_publication_request"]!["identifier"])\", \"seqs\":[1337]}}")
        
        // Queue drained (due to async publishing behavior)
        expect(syncClient.queuedEvents.count).toEventually(equal(0))
        expect(syncClient.publishedEvents.count).to(equal(1))
        
        // Verify if the response took care of the event
        let publishedEvent = syncClient.publishedEvents[0]
        expect(publishedEvent.seq).to(equal(1337))
    }
}
