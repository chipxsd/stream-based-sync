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
    
    @IBOutlet weak var backgroundImage: UIImageView!
    private var _lightSwitchState = false;
    private var lightSwitchClient: LightSwitchClient?
    private var audioPlayer: AVAudioPlayer?
    
    override func viewDidLoad() {
        self.lightSwitchClient = LightSwitchClient(hostURL: NSURL(string: "ws://192.168.90.102:8080/")!)
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
                return;
            }
            self._lightSwitchState = newValue
            backgroundImage.highlighted = newValue;
            self.playSound(newValue == true ? "lightsOn" : "lightsOff")
        }
    }

    /**
     Toggles the private ivar `_lightSwitchState` boolean, updates the
     backgrund image, plays a sound and transmits the change over network.
     */
    func toggleLightSwitch() {
        self.lightSwitchState = !self.lightSwitchState;
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
     LightSwitchClientDelegate function implementation
     */
    func lightSwitchClientDidReceiveChange(client: LightSwitchClient, lightsOn: Bool) {
        self.lightSwitchState = lightsOn;
    }
}

