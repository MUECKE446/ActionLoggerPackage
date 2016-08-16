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
//        let textViewDestination = ActionLogTextViewDestination(identifier:"textView",textView: outputTextView)
        let textViewDestination = ActionLogXcodeConsoleSimulationDestination(identifier:"textView",textView: outputTextView)
        
        let log = ActionLogger(identifier: "newLogger",logDestinations: [textViewDestination])
        log!.info("let us start with a NSTextView")
        log!.verbose("it looks good")
        log!.error("this is only a message in category: error")
        outputLogLines(linesNumber: 1000, log: log!)
        
    }
    
    func outputLogLines(linesNumber linesNumber: Int, log: ActionLogger) {
        for i in 1 ... linesNumber {
            log.debug("\(i): this is a line for output \(i)")
        }
    }

    func fixAttributesInTextView() {
        let s = outputTextView.textStorage!.string
        let string: MyMutableAttributedString = MyMutableAttributedString(string: s)
//        var s1 = MyMutableAttributedString()
//        s1.appendAttributedString(NSMutableAttributedString(string: s))
        
        string.fixAttributesInRange(NSRange.init(location: 0, length: string.length))
        outputTextView.textStorage!.replaceCharactersInRange(NSRange.init(location: 0, length: string.length), withAttributedString: string)
        
    }
    
}

