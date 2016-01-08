//
//  TransportTests.swift
//  example-02-todo-list
//
//  Created by Klemen Verdnik on 1/6/16.
//  Copyright © 2016 Klemen Verdnik. All rights reserved.
//

import XCTest
import Nimble
import Starscream

class TransportTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testObjectSerialization() {
        let transport = MockTransport(hostURL: NSURL(string: "ws://fakeurl:8080/")!, serializableClassRootKeys: [ "hotSauce": MockHotSauce.self])
        let tabasco = MockHotSauce.Tabasco()

        transport.send(tabasco)
        let expectedString = transport.mockWebSocketClient.sentText[0]
        expect(expectedString).to(equal("{\n  \"hotSauce\" : {\n    \"scovilleRating\" : 2500,\n    \"name\" : \"Tabasco\"\n  }\n}"))
    }
    
    func testObjectDeserialization() {
        let transportableObject = MockTransportableObject()
        let transport = MockTransport(hostURL: NSURL(string: "ws://fakeurl:8080/")!, serializableClassRootKeys: [ "hotSauce": MockHotSauce.self])
        transport.delegate = transportableObject
        
        transport.mockWebSocketClient.mockReceivedText("{\n  \"hotSauce\" : {\n    \"scovilleRating\" : 2500,\n    \"name\" : \"Tabasco\"\n  }\n}")
        let expectedObject = transportableObject.receivedObjects[0]
        expect((expectedObject as! MockHotSauce).name).to(equal("Tabasco"))
        expect((expectedObject as! MockHotSauce).scovilleRating).to(equal(2500))
    }
    
    func testSendingRequestCallsCompletionWhenDisconnected() {
        let transportableObject = MockTransportableObject()
        let transport = MockTransport(hostURL: NSURL(string: "ws://fakeurl:8080/")!, serializableClassRootKeys: [ "hotSauce": MockHotSauce.self, "request": RPCObject.self ])
        transport.delegate = transportableObject
        transport.mockWebSocketClient.mockConnected = false
        
        let request = RPCObject(identifier: NSUUID())
        expect(request).toNot(beNil())
        var requestCompleted = false
        transport.send(request) { (success: Bool, response: RPCObject?) -> Void in
            expect(success).to(beFalse())
            expect(response).to(beNil())
            requestCompleted = true
        }
        // Waiting for response
        expect(requestCompleted).toEventually(beTrue())
    }

    func testSendingRequestCallsCompletionWhenConnectionCloses() {
        let transportableObject = MockTransportableObject()
        let transport = MockTransport(hostURL: NSURL(string: "ws://fakeurl:8080/")!, serializableClassRootKeys: [ "hotSauce": MockHotSauce.self, "request": RPCObject.self ])
        transport.delegate = transportableObject
        transport.mockWebSocketClient.mockConnected = true
        
        let request = RPCObject(identifier: NSUUID())
        expect(request).toNot(beNil())
        var requestCompleted = false
        transport.send(request) { (success: Bool, response: RPCObject?) -> Void in
            expect(success).to(beFalse())
            expect(response).to(beNil())
            requestCompleted = true
        }
        
        // Force a disconnect -- which should end any pending requests.
        transport.disconnect()
        
        // Waiting for response
        expect(requestCompleted).toEventually(beTrue())
    }
    
    func testSendingRequestCallsCompletionWhenConnected() {
        let transportableObject = MockTransportableObject()
        let transport = MockTransport(hostURL: NSURL(string: "ws://fakeurl:8080/")!, serializableClassRootKeys: [ "hotSauce": MockHotSauce.self, "request": RPCObject.self ])
        transport.delegate = transportableObject
        transport.mockWebSocketClient.isConnected = true
        
        let request = RPCObject(identifier: NSUUID())
        expect(request).toNot(beNil())
        var requestCompleted = false
        transport.send(request) { (success: Bool, response: RPCObject?) -> Void in
            expect(success).to(beTrue())
            expect(response).toNot(beNil())
            expect(response!.identifier).to(equal(request.identifier))
            requestCompleted = true
        }
        // Verifying request serialization
        let serializedRequest = transport.mockWebSocketClient.sentText[0]
        let expectedString = "{\n  \"request\" : {\n    \"identifier\" : \"\(request.identifier.UUIDString)\"\n  }\n}"
        expect(serializedRequest).to(equal(expectedString))

        // Faking a sent response
        transport.mockWebSocketClient.mockReceivedText(expectedString)
        
        // Waiting for response
        expect(requestCompleted).toEventually(beTrue())
    }
}
