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
}
