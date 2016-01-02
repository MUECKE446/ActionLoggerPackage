//
//  ViewController.swift
//  ActionLoggerExample_1
//
//  Created by Christian Muth on 13.12.15.
//  Copyright © 2015 Christian Muth. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    // this can used for output log messages
    @IBOutlet var outputTextView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.textViewController = self

    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func generateOutputToTextViewInWindow() {
        let textViewDestination = ActionLogTextViewDestination(identifier:"textView",textView: outputTextView)
        let log = ActionLogger(identifier: "newLogger",logDestinations: [textViewDestination])
        log!.info("let us start with a NSTextView")
        log!.verbose("it looks good")
        log!.error("this is only a message in category: error")
        outputLogLines(linesNumber: 1000, log: log!)
        
    }
    
    func outputLogLines(linesNumber linesNumber: Int, log: ActionLogger) {
//        var logQueue = dispatch_queue_create("myovlyQueue", nil)
//        dispatch_sync(logQueue) {
            for i in 1 ... linesNumber {
                log.info("\(i): this is a line for output \(i)")
            }
//        }
    }

}

