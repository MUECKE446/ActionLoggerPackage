//
//  AppDelegate.swift
//  ActionLoggerExample_1
//
//  Created by Christian Muth on 13.12.15.
//  Copyright © 2015 Christian Muth. All rights reserved.
//

import Cocoa

// with referencing ActionLogger class a default ActionLogger is created
// with this global constant you can use logger in all other files
let logger = ActionLogger.defaultLogger()

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var textViewController: ViewController?

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    /// you will see the messages for each LogLevel in different Colors in Xcode console (if you have installed the XcodeColors PlugIn)
    /// If you have additional installed the PlugIn MCLogForActionLogger you can try the filterfunctions
    /// choose different levels of output in the bottom left of the console and watch the output in the console.
    /// also you can try the filter functions in the search field at the bottom of the console
    /// if you precede the search with a @ char, the search is interpreted as a regular expression
    @IBAction func generateLineForEachLevel(sender: NSMenuItem) {
        generateLineForEachLevel()
        logger.logSetupValues()
        textViewController?.outputLogLines(linesNumber: 1000, log: logger)
        
        
    }
    
    func generateLineForEachLevel() {
        logger.messageOnly("this is the line for level: MessageOnly")
        logger.comment("this is the line for level: Comment")
        logger.verbose("this is the line for level: Verbose")
        logger.info("this is the line for level: Info")
        logger.debug("this is the line for level: Debug")
        logger.warning("this is the line for level: Warning")
        logger.error("this is the line for level: Error")
        logger.severe("this is the line for level: Severe")
    }

    @IBAction func generateOutputToTextViewInWindow(sender: NSMenuItem) {
        if let _ = textViewController {
            textViewController!.generateOutputToTextViewInWindow()
        }
    }
}

