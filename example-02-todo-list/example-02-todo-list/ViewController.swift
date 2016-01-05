//
//  ViewController.swift
//  example-02-todo-list
//
//  Created by Klemen Verdnik on 1/2/16.
//  Copyright © 2016 Klemen Verdnik. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func test() {
        let todoList = Todo.List()
        let task = Todo.Task(identifier: NSUUID(), completed: false, title: "Buy Milk", label: Todo.Task.ColorLabel.None)
        let event = todoList.remove(task.identifier)
        print("event '\(event)", event)
    }


}

