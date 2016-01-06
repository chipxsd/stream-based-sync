//
//  Transport.swift
//  example-02-todo-list
//
//  Created by Klemen Verdnik on 1/5/16.
//  Copyright © 2016 Klemen Verdnik. All rights reserved.
//

import Foundation

public protocol Trasportable: class {
    /// Instance variable to the transport layer.
    var transport: Transport { get }

    /**
     Invoked when transport receives an object.
     
     - parameter transport: Transportable object instance making the call.
     - parameter object:    Deserialized object received by the transport.
     */
    func transport(transport: Transport, didReceiveObject object: Serializable)
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

public class Transport: NSObject {
    
}
