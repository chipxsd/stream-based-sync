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

/// Convenience alias for the completion closure definition.
public typealias RequestCompletionBlock = (success: Bool, response: Transport.RPCObject?) -> Void

public class Transport: NSObject, WebSocketDelegate {
    /// The Starscream `WebSocket` client.
    internal var webSocketClient: WebSocket
    
    /// The URL where the transport should connect to, set at init.
    public internal(set) var hostURL: NSURL
    
    /// Weak reference to the delegate (transport callback receiver).
    public weak var delegate: TransportDelegate?
    
    /// A lookup table of de-serializable objects names and types.
    public var serializableClassRootKeys: Dictionary<String, Serializable.Type>

    /// Dictionary of requests in progress.
    private var requestsInProgress = Dictionary<NSUUID, RPCCompletionPair>()
    
    private class RPCCompletionPair: NSObject {
        var request: RPCObject
        var completion: RequestCompletionBlock
        init (request: RPCObject, completion: RequestCompletionBlock) {
            self.request = request
            self.completion = completion
        }
    }
    
    /// Base RPC structure (for requests and responses)
    public class RPCObject: NSObject, Serializable {
        public private(set) var identifier = NSUUID()
        
        init(identifier: NSUUID) {
            self.identifier = identifier
        }
        
        public required init(fromDictionary dictionary: Dictionary<String, AnyObject>) {
            self.identifier = NSUUID(UUIDString: dictionary["identifier"] as! String)!
        }
        
        public func toDictionary() -> Dictionary<String, AnyObject> {
            return [ "identifier": self.identifier ]
        }
    }
    
    /// Instance variable indicating the connection state.
    public var isConnected: Bool {
        get {
            return self.webSocketClient.isConnected
        }
    }
    
    init(hostURL: NSURL, serializableClassRootKeys: Dictionary<String, Serializable.Type>) {
        self.webSocketClient = WebSocket(url: hostURL)
        self.hostURL = hostURL
        self.serializableClassRootKeys = serializableClassRootKeys
        super.init()
        self.webSocketClient.delegate = self
    }
    
    public func connect() {
        self.webSocketClient.connect()
    }
    
    public func disconnect() {
        self.webSocketClient.disconnect()
    }
    
    public func send(object: Serializable) {
        let serializedObject = object.toDictionary()
        let JSONObject: Dictionary<String, AnyObject> = [ self.rootKey(object.dynamicType)!: serializedObject ]
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
    
    public func send(request: RPCObject, completion: RequestCompletionBlock) {
        self.requestsInProgress[request.identifier] = RPCCompletionPair(request: request, completion: completion)
        self.send(request)
    }
    
    /* WebSocketDelegate method implementation */
    public func websocketDidConnect(socket: WebSocket) {
        self.delegate?.transportDidConnect(self)
    }
    
    public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        // Abort all requests that were in progress.
        self.requestsInProgress.values.forEach({ $0.completion(success: false, response: nil) })
        self.requestsInProgress = [:]
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
        for rootKey in self.serializableClassRootKeys.keys {
            let subDictionary = JSONObject![rootKey] as? Dictionary<String, AnyObject>
            if subDictionary != nil {
                // Deserialize incoming JSON dictionary
                // to `Serializable` object instance.
                let classType = self.serializableClassRootKeys[rootKey]
                let deserializedObject = classType?.init(fromDictionary: subDictionary!)
                if deserializedObject == nil {
                    continue
                }
                
                if let response = deserializedObject as? RPCObject {
                    // If the deserialized object we received is a type of
                    // RPC, it's a response to our request we made earlier.
                    let originalRequest = self.requestsInProgress[response.identifier]
                    originalRequest?.completion(success: true, response: response)
                } else {
                    // Otherwise, it's a pushed object.
                    self.delegate?.transport(self, didReceiveObject: deserializedObject!)
                }
            }
        }
    }
    
    public func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        // no op
    }
    
    private func rootKey(type: Serializable.Type) -> String? {
        for rootKey in self.serializableClassRootKeys.keys {
            if (self.serializableClassRootKeys[rootKey] == type) {
                return rootKey
            }
        }
        return nil
    }
}
