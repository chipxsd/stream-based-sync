//
//  LightSwitchClient.swift
//  example-01-light-switch
//
//  Created by Klemen Verdnik on 12/11/15.
//  Copyright © 2015 Klemen Verdnik. All rights reserved.
//

import UIKit
import Starscream

public protocol LightSwitchClientDelegate: class {
    func lightSwitchClientDidReceiveChange(client: LightSwitchClient, lightsOn: Bool)
}

public class LightSwitchClient: NSObject, WebSocketDelegate {

    /// The Starscream `WebSocket` client.
    var webSocketClient: WebSocket
    
    /// Delegate in charge of receiving Light Switch updates.
    public weak var delegate: LightSwitchClientDelegate?

    /**
     Initializes a web socket client and connects to the given URL host address.
     
     - Parameter hostURL: The URL address the web socket will connect to.
     */
    init(hostURL: NSURL) {
        self.webSocketClient = WebSocket(url: hostURL)
        super.init()
        self.webSocketClient.connect()
        self.webSocketClient.delegate = self
    }

    /**
     Transmits the light switch state to the server
    
     - Parameter lightsOn: A boolean value representing the light switch state.
     */
    public func sendLightSwitchState(lightsOn: Bool) {
        let lightSwitchStateDict = ["lightsOn" : lightsOn]
        var JSONString: String?
        do {
            let JSONData = try NSJSONSerialization.dataWithJSONObject(lightSwitchStateDict, options: NSJSONWritingOptions.PrettyPrinted)
            JSONString = String(data: JSONData, encoding: NSUTF8StringEncoding)!
        } catch {
            print("Failed serializing dictionary to a JSON object with \(error)")
        }
        if JSONString != nil {
            self.webSocketClient.writeString(JSONString!)
        }
    }
    
    /**
     WebSocket's delegate method invoked by the `WebSocket` client upon
     receiving a string body.
     
     - Parameter socket: A `WebSocket` client performing the call on the method.
     - Parameter text: The text body received by the `WebSocket` client.
     */
    public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        let JSONData = text.dataUsingEncoding(NSUTF8StringEncoding)
        var lightSwitchStateDict: Dictionary<String, AnyObject>?
        do {
            lightSwitchStateDict = try NSJSONSerialization.JSONObjectWithData(JSONData!, options: NSJSONReadingOptions.AllowFragments) as? Dictionary<String, AnyObject>
        } catch {
            print("Failed deserializing the JSON object with \(error)")
        }
        if lightSwitchStateDict != nil {
            self.delegate?.lightSwitchClientDidReceiveChange(self, lightsOn: lightSwitchStateDict?["lightsOn"] as! Bool)
        }
    }
    
    public func websocketDidConnect(socket: WebSocket) {
        
    }
    
    public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        
    }
    
    public func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        
    }
}
