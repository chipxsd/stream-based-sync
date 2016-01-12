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
    
    public override func connect() {
        self.mockConnected = true
        self.delegate?.websocketDidConnect(self)
    }

    override public func disconnect(forceTimeout: Int) {
        self.mockConnected = false
        self.delegate?.websocketDidDisconnect(self, error: nil)
    }
    
    override public var isConnected: Bool {
        get {
            return self.mockConnected
        } set {
            // noop
        }
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

class MockModelReconciler: NSObject, ModelReconciler {
    var appliedEvents = Array<Sync.Event>()
    weak var outboundEventReceiver: OutboundEventReceiver?
    func apply(events: Array<Sync.Event>) -> Bool {
        appliedEvents.appendContentsOf(events)
        return true
    }
    func mockDidCreateEvent(event: Sync.Event) {
        self.outboundEventReceiver?.reconciler(self, didCreateEvent: event)
    }
}

class MockOutboundReconciler: NSObject, OutboundEventReceiver {
    var modelReconciler: ModelReconciler
    var mockSeqPointer = Sync.SeqPointer(precedingSeq: 0, clientSeq: 0)
    var createdEvents = Array<Sync.Event>()
    init(modelReconciler: ModelReconciler) {
        self.modelReconciler = modelReconciler
    }
    /* Reconciler protocol implementation */
    internal func reconcilerWillCreateEvent(reconciler: ModelReconciler) -> Sync.SeqPointer {
        return self.mockSeqPointer
    }
    internal func reconciler(reconciler: ModelReconciler, didCreateEvent event: Sync.Event) {
        self.createdEvents.append(event)
    }
}
