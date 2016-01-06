//
//  Transport.swift
//  example-02-todo-list
//
//  Created by Klemen Verdnik on 1/5/16.
//  Copyright © 2016 Klemen Verdnik. All rights reserved.
//

import Foundation
import Starscream

public protocol TransportDelegate: class {
    /**
     Invoked when transport receives an object.
     
     - parameter transport: Transportable object instance making the call.
     - parameter object:    Deserialized object received by the transport.
     */
    func transport(transport: Transport, didReceiveObject object: Serializable)
    
    /**
     Invoked when transport successfully connects to the server.
     
     - parameter transport: Transportable object instance making the call.
     */
    func transportDidConnect(transport: Transport)

    /**
     Invoked when transport disconnects from the server.
     
     - parameter transport: Transportable object instance making the call.
     */
    func transportDidDisconnect(transport: Transport)
}

public protocol Serializable: class {
    /**
     Method initializes the object with values from dictionary.
     
     - parameter dictionary: Dictionary with keys and values matching
                             classes properties.
     */
    init(fromDictionary dictionary: Dictionary<String, AnyObject>)
    
    /**
     Returns a dictionary representation of the object.
     
     - returns: Dictionary representation of the object.
     */
    func toDictionary() -> Dictionary<String, AnyObject>
}

public class Transport: NSObject, WebSocketDelegate {
    /// The Starscream `WebSocket` client.
    private var webSocketClient: WebSocket
    
    /// Instance variable indicating the connection state.
    public var isConnected: Bool = false
    
    /// The URL where the transport should connect to, set at init.
    public private(set) var hostURL: NSURL
    
    /// Weak reference to the delegate (transport callback receiver).
    public weak var delegate: TransportDelegate?
    
    /// A lookup table of de-serializable objects names and types.
    public var serializableClassTypes: Dictionary<String, Serializable.Type>
    
    init(hostURL: NSURL, modelReconciler: ModelReconciler, serializableClassTypes: Dictionary<String, Serializable.Type>) {
        self.webSocketClient = WebSocket(url: hostURL)
        self.hostURL = hostURL
        self.serializableClassTypes = serializableClassTypes
        super.init()
        self.webSocketClient.delegate = self
    }
    
    public func connect() {
        self.webSocketClient.connect()
    }
    
    public func disconnect() {
        self.webSocketClient.disconnect()
    }
    
    public func send(object: Serializable)
    {
        let JSONObject = object.toDictionary()
        var JSONString: String?
        do {
            let JSONData = try NSJSONSerialization.dataWithJSONObject(JSONObject, options: NSJSONWritingOptions.PrettyPrinted)
            JSONString = String(data: JSONData, encoding: NSUTF8StringEncoding)!
        } catch {
            print("Failed serializing dictionary to a JSON object with \(error)")
        }
        if JSONString != nil {
            self.webSocketClient.writeString(JSONString!)
        }
    }
    
    /* WebSocketDelegate method implementation */
    public func websocketDidConnect(socket: WebSocket) {
        self.delegate?.transportDidConnect(self)
    }
    
    public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        self.delegate?.transportDidDisconnect(self)
    }
    
    public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        let JSONData = text.dataUsingEncoding(NSUTF8StringEncoding)
        var JSONObject: Dictionary<String, AnyObject>?
        do {
            JSONObject = try NSJSONSerialization.JSONObjectWithData(JSONData!, options: NSJSONReadingOptions.AllowFragments) as? Dictionary<String, AnyObject>
        } catch {
            print("Failed deserializing the JSON object with \(error)")
        }
        // Exit early, if no JSON objects found in text
        if JSONObject == nil {
            return
        }
        // Check if the JSON object is a deserializable structure.
        for className in self.serializableClassTypes.keys {
            let subDictionary = JSONObject![className] as? Dictionary<String, AnyObject>
            if subDictionary != nil {
                let classType = self.serializableClassTypes[className]
                let deserializedObject = classType?.init(fromDictionary: subDictionary!)
                if deserializedObject != nil {
                    self.delegate?.transport(self, didReceiveObject: deserializedObject!)
                }
            }
        }
    }
    
    public func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        // no op
    }
}
