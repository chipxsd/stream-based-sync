//
//  ViewController.swift
//  example-01-light-switch
//
//  Created by Klemen Verdnik on 12/10/15.
//  Copyright © 2015 Klemen Verdnik. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, LightSwitchClientDelegate {
    
    /// Reference to the `backgroundImage` instantiated in the storyboard.
    @IBOutlet weak var backgroundImage: UIImageView!

    /// The local Light Switch state.
    private var _lightSwitchState = false
    
    /// Light Switch Client using the web socket.
    private var lightSwitchClient: LightSwitchClient?
    
    /// The `AVAudioPlayer` instance that gets instantated in
    /// `func playSound(...)` we keep as a local instance.
    private var audioPlayer: AVAudioPlayer?
    
    override func viewDidLoad() {
        self.lightSwitchClient = LightSwitchClient(hostURL: NSURL(string: "ws://10.0.17.1:8080/")!)
        self.lightSwitchClient?.delegate = self
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    /**
     Full screen button didTouchUpInside event handling.
     
     - Parameter sender: The sender invoking the function.
     */
    @IBAction func onButtonDidTouchUpInside(sender: AnyObject) {
        self.toggleLightSwitch()
    }

    /**
     Sets the new value for the private ivar `_lightSwitchState` and updates the
     background image and plays a corresponding sound.
     */
    private var lightSwitchState: Bool {
        get {
            return self._lightSwitchState
        }
        set {
            if newValue == self._lightSwitchState {
                return
            }
            self._lightSwitchState = newValue
            backgroundImage.highlighted = newValue
            self.playSound(newValue == true ? "lightsOn" : "lightsOff")
        }
    }

    /**
     Toggles the private ivar `_lightSwitchState` boolean, updates the
     backgrund image, plays a sound and transmits the change over network.
     */
    func toggleLightSwitch() {
        self.lightSwitchState = !self.lightSwitchState
        self.lightSwitchClient?.sendLightSwitchState(self.lightSwitchState)
    }

    /**
     Plays a sound from the resources bundle with a given file name.
     
     - Parameter soundName: The filename of the sound.
     */
    func playSound(soundName: String) {
        let soundFileURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(soundName, ofType: "m4a")!)
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOfURL:soundFileURL)
            self.audioPlayer!.prepareToPlay()
            self.audioPlayer!.play()
        } catch let error {
            print("Failed to play sound named '\(soundName)' with \(error)")
        }
    }
    
    /**
     LightSwitchClientDelegate function implementation, which gets executed
     whenever a new light switch state comes in from the network. The new state
     gets stored in a local variable `self.lightSwitchState`.
     
     - Parameter client: The `LightSwitchClient` executing the function.
     - Parameter lightsOn: The new Light Switch state coming from network.
     */
    func lightSwitchClientDidReceiveChange(client: LightSwitchClient, lightsOn: Bool) {
        self.lightSwitchState = lightsOn
    }
}

