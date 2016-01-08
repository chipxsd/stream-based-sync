//
//  TestMocks.swift
//  example-02-todo-list
//
//  Created by Klemen Verdnik on 1/6/16.
//  Copyright © 2016 Klemen Verdnik. All rights reserved.
//

import UIKit
import Starscream

class MockHotSauce: Serializable {
    private(set) var name: String
    private(set) var scovilleRating: Int
    
    init(name: String, scovilleRating: Int) {
        self.name = name
        self.scovilleRating = scovilleRating
    }
    
    required init(fromDictionary dictionary: Dictionary<String, AnyObject>) {
        self.name = dictionary["name"] as! String
        self.scovilleRating = dictionary["scovilleRating"] as! Int
    }
    
    func toDictionary() -> Dictionary<String, AnyObject> {
        return [ "name": self.name, "scovilleRating": self.scovilleRating ] as Dictionary<String, AnyObject>
    }
    
    static func Tapatío() -> MockHotSauce {
        return MockHotSauce(name: "Tapatío", scovilleRating: 3000)
    }
    
    static func Tabasco() -> MockHotSauce {
        return MockHotSauce(name: "Tabasco", scovilleRating: 2500)
    }
    
    static func Sriracha() -> MockHotSauce {
        return MockHotSauce(name: "Sriracha", scovilleRating: 2200)
    }
}

public class MockWebSocket: WebSocket {
    var url: NSURL
    var sentText: Array<String> = []
    var mockConnected: Bool = true
    override init(url: NSURL) {
        self.url = url
        super.init(url: url)
    }
    
    func mockReceivedText(text: String) {
        self.delegate?.websocketDidReceiveMessage(self, text: text)
    }
    
    override public func writeString(str: String) {
        self.sentText.append(str)
    }
    
    override public var isConnected: Bool {
        get {
            return self.mockConnected
        } set {
            self.mockConnected = isConnected
        }
    }
    
    override public func disconnect(forceTimeout: Int) {
        self.delegate?.websocketDidDisconnect(self, error: nil)
    }
}

class MockTransport: Transport {
    var mockWebSocketClient: MockWebSocket
    override init(hostURL: NSURL, serializableClassRootKeys: Dictionary<String, Serializable.Type>) {
        self.mockWebSocketClient = MockWebSocket(url: hostURL)
        super.init(hostURL: hostURL, serializableClassRootKeys: serializableClassRootKeys)
        self.webSocketClient = self.mockWebSocketClient
        self.mockWebSocketClient.delegate = self
    }
}

class MockTransportableObject: NSObject, TransportDelegate {
    var receivedObjects: Array<Serializable> = []
    var connectionStateChanges: Array<Bool> = []
    
    func transportDidConnect(transport: Transport) {
        self.connectionStateChanges.append(true)
    }
    
    func transportDidDisconnect(transport: Transport) {
        self.connectionStateChanges.append(false)
    }
    
    func transport(transport: Transport, didReceiveObject object: Serializable) {
        self.receivedObjects.append(object)
    }
}
