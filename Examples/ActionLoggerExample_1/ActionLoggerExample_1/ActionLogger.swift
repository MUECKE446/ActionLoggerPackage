//
//  ActionLogger.swift
//
//  Created by Christian Muth on 12.04.15.
//  Copyright (c) 2015 Christian Muth. All rights reserved.
//

/**
    Version 1.0.0:  the starter with outputs to the Xcode console and/or files

    Version 1.1.0:  add a new ActionLogdestination -> ActionLogTextViewdestination writes output into (NS/UI)TextView control

    Version 1.1.1:  add the new ActionLogDestination to some functions (bug fix)
                    add outputLogLevel to ActionLogDestinatianProtocoll -> some functions come very easier
                    add Quick Help descriptions, which are also used for documentation with jazzy

    Version 1.1.2:  sometimes in testing it seems, that on beginning of logging some text is missing. But this could'nt reproduced.
                    Therefore I try it without a queue. The queue was used, to hold messages together, if more ActionLogger objects in separate threads
                    outputs to Xcode console.
                    

*/


import Foundation
#if os(OSX)
    import AppKit
#endif
#if os(iOS)
    import UIKit
#endif

// Version see at the begin of class ActionLogger


// MARK: - ActionLogDetails
// - Data structure to hold all info about a log message, passed to log destination classes

/// this structure holds all informations of a log message
/// and is passed to the log destination classes
///
/// **properties:**
///
/// * `var logLevel: ActionLogger.LogLevel` -> the LogLevel of this message
/// * `var date: NSDate` -> date and time of this message
/// * `var logMessage: String` -> the pure text message
/// * `var functioneName: String`-> the function name, where the message is generated
/// * `var fileName: String`-> the file name, where the message is created
/// * `var linNumber: Int` -> the line number in the file, where the message is generated
///
public struct ActionLogDetails {
    /// the LogLevel of this message
    var logLevel: ActionLogger.LogLevel
    /// date and time of this message
    var date: NSDate
    /// the pure text message
    var logMessage: String
    /// the function name, where the message is generated
    var functionName: String
    /// the file name, where the message is created
    var fileName: String
    /// the line number in the file, where the message is generated
    var lineNumber: Int
    
    /// initialize an ActionLogDetails struct
    ///
    /// **parameters** see on struct ActionLogDetails
    ///
    init(logLevel: ActionLogger.LogLevel, date: NSDate, logMessage: String, functionName: String, fileName: String, lineNumber: Int) {
        self.logLevel = logLevel
        self.date = date
        self.logMessage = logMessage
        self.functionName = functionName
        self.fileName = fileName
        self.lineNumber = lineNumber
    }
}

// MARK: - ActionLogger
/**
####Overview:

The Action Logger class sends messages to the Xcode console and / or a file or a NSTextView object (very new!!!). The messages are processed accordingly before they are issued.
If the Xcode Plugin XcodeColors is installed, the messages in the Xcode console are displayed in color.
The aim of the development was to implement a very easy-to-use method that can be generated with the reports to track program run during software testing. On the other hand has been achieved that through a variety of options, the class can also be used for any other protocol tasks.
See two example outputs

![alt tag](https://cloud.githubusercontent.com/assets/6715559/11895791/a38a1694-a581-11e5-8a0f-b244118d45a2.png)

![alt tag](https://cloud.githubusercontent.com/assets/6715559/11895795/ab8e6598-a581-11e5-8da4-bc2c59592943.png)

####general description:

A message line consists of individually assembled components:

{Date+Time}▫︎[{LogLevel}]▫︎[{Filename}:{LineNumber}]▫︎{Functionname}▫︎:▫︎{Messagetext}

Components are enclosed in {},
▫︎ means space

By default, all components are selected. Each of these components can be turned off (not the message text).

####Use:

The use of Action Logger class in your project is very simple:

Drag the file ActionLoggerComplete.swift file from Finder directly in Xcode project.
in AppDelegate.swift immediately after the imports, insert the following:

```
// Get a reference to defaultLoggerlet
log = ActionLogger.defaultLogger ()
```

Once the Action Logger class is referenced once, a default logger is automatically created. The default logger specifies the Xcode Debug Console.

The logger log can now be used in all other .swift files in your project.

```
log.verbose("this message is generated in ViewController")
ActionLogger.info("here is an info for you")
```

![alt tag](https://cloud.githubusercontent.com/assets/6715559/11776753/f29b0af8-a249-11e5-983a-ffb788dc4892.png)

As the above example shows, it's even easier: all outputs can also be done via class methods. Step 2 of this procedure could also be left out! If you will use the class methods used internally also the default logger automatically generated.
*/
public class ActionLogger : CustomDebugStringConvertible {
    
    // MARK: - class wide vars
    public class var dateFormatterGER: NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.locale =  NSLocale.currentLocale()
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss.SSS"
        return formatter
    }
    
    public class var dateFormatterUSA: NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.locale =  NSLocale.currentLocale()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }
    
    // MARK: - Version
    let integerCharSet = NSCharacterSet(charactersInString: "+-0123456789")
    
    // read only computed properties
    /// most importent number of version **X**.Y.Z
    public var ActionLoggerVersionX: Int {
        let scanner = NSScanner(string: constants.ActionLoggerVersion)
        while let _ = scanner.scanUpToCharactersFromSet(integerCharSet) {}
        return scanner.scanInteger()!
    }
    
    /// middle number of version X.**Y**.Z
    public var ActionLoggerVersionY: Int {
        let scanner = NSScanner(string: constants.ActionLoggerVersion)
        while let _ = scanner.scanUpToCharactersFromSet(integerCharSet) {}
        scanner.scanInteger()!
        while let _ = scanner.scanUpToCharactersFromSet(integerCharSet) {}
        return scanner.scanInteger()!
    }
    
    /// least importent number of version X.Y.**Z**
    public var ActionLoggerVersionZ: Int {
        let scanner = NSScanner(string: constants.ActionLoggerVersion)
        while let _ = scanner.scanUpToCharactersFromSet(integerCharSet) {}
        scanner.scanInteger()!
        while let _ = scanner.scanUpToCharactersFromSet(integerCharSet) {}
        scanner.scanInteger()!
        while let _ = scanner.scanUpToCharactersFromSet(integerCharSet) {}
        return scanner.scanInteger()!
    }
    
    
    // MARK: - Constants
    struct constants {
        static let defaultLoggerIdentifier = "de.muecke-software.ActionLogger.defaultLogger"
        static let baseConsoleDestinationIdentifier = "de.muecke-software.ActionLogger.logdestination.console"
        /**
         bei
         Veränderung der Schnittstelle                       X
         Starker Veränderung der Funktionalität				X
         
         Erweiterung der Funktionalität (alte bleibt aber erhalten)	Y
         Veränderung der Funktionalität wegen Bug Fixing               Y
         
         Veränderung des internen Codes ohne die Funktionalität
         zu verändern (CodeLifting, interne Schönheit)			Z
         
         X	die verwendenden Applikationen müssen hinsichtlich der vorgenommenen Veränderungen oder auf Grund der geänderten Schnittstellen hin untersucht werden.
         
         Y	Veränderungen in Applikation überprüfen
         
         Z	nur Austausch der Datei ActionLogger.swift nötig
         
         ** !!! Achtung: die Version als String befindet sich bei constants! **
         */
        static let ActionLoggerVersion: String = "1.1.2"
    }
    
    struct statics {
        static var loggerDict = [String: ActionLogger]()
        static let defaultLogger: ActionLogger! = ActionLogger(identifier:ActionLogger.constants.defaultLoggerIdentifier)
        static let standardLogConsoleDestination: ActionLogDestinationProtocol =  ActionLogConsoleDestination(identifier: ActionLogger.constants.baseConsoleDestinationIdentifier)
    }
    
    public var dateFormatter: NSDateFormatter
    
    // MARK: - Enums
    /// the possible values of LogLevel for a log message
    ///
    /// it depends on the objects outputLogLevel and the LogLevel of the message whether a message is really written to the output
    ///
    /// only log messages with a LogLevel >= outputLogLevel are written out
    public enum LogLevel: Int, Comparable {
        case AllLevels = 0,
        MessageOnly,
        Comment,
        Verbose,
        Info,
        Debug,
        Warning,
        Error,
        Severe
        
        func description() -> String {
            switch self {
            case .AllLevels:
                return "AllLevels"
            case .MessageOnly:
                return "MessageOnly"
            case .Comment:
                return "Comment"
            case .Verbose:
                return "Verbose"
            case .Debug:
                return "Debug"
            case .Info:
                return "Info"
            case .Warning:
                return "Warning"
            case .Error:
                return "Error"
            case .Severe:
                return "Severe"
            }
        }
    }
    
    // MARK: - Properties
    /// the (unique) identifier for an ActionLogger object
    public let identifier: String
    
    /// the current outputLogLevel for the ActionLogger object
    ///
    /// only log messages with a LogLevel >= outputLogLevel are written out
    public var outputLogLevel: LogLevel = .AllLevels {
        didSet {
            for logDestination in logDestinations {
                if logDestination is ActionLogConsoleDestination {
                    let tmpDestination = logDestination as! ActionLogConsoleDestination
                    tmpDestination.outputLogLevel = outputLogLevel
                    return
                }
                if logDestination is ActionLogFileDestination {
                    let tmpDestination = logDestination as! ActionLogFileDestination
                    tmpDestination.outputLogLevel = outputLogLevel
                    return
                }
            }
        }
    }
    
    /// an array with all logDestinations of this ActionLogger object
    ///
    /// an ActionLogger can have 1, 2 or more logDestinations e.g.: console and file
    ///
    /// - Note: this var is not public
    var logDestinations = [ActionLogDestinationProtocol]()
    
    // MARK: - initializer
    init?(id: String, withStandardConsole: Bool = true) {
        self.dateFormatter = ActionLogger.dateFormatterGER
        self.identifier = id
        if let _ = statics.loggerDict[identifier] {
            ActionLogger.defaultLogger().error("unable to initialize ActionLogger instance with identifier: \"\(identifier)\" allways exists")
            return nil
        }
        statics.loggerDict[identifier] = self
        if withStandardConsole {
            addLogDestination(ActionLogger.statics.standardLogConsoleDestination)
        }
    }
    
    convenience init?(identifier: String, logDestinations: [ActionLogDestinationProtocol]? = nil) {
        self.init(id: identifier, withStandardConsole: false)
        if let logDests = logDestinations {
            for logDest in logDests {
                addLogDestination(logDest)
            }
        }
        else {
            addLogDestination(ActionLogger.statics.standardLogConsoleDestination)
        }
    }
    
    public convenience init?() {
        self.init(identifier:NSBundle.mainBundle().bundleIdentifier!)
    }
    
    public convenience init?(logFile withLogFile: String) {
        self.init(id: withLogFile, withStandardConsole: false)
        if let logFileDestination = ActionLogFileDestination(writeToFile: withLogFile) {
            self.addLogDestination(logFileDestination)
        }
        else {
            ActionLogger.defaultLogger().error("could not instantiate ActionLogger instance")
            return nil
        }
    }
    
    deinit {
        // remove Logger from dict
        statics.loggerDict[self.identifier] = nil
    }
    
    // MARK: - DefaultLogger
    /// the defaultLogger is created with the first reference to the class ActionLogger
    ///
    /// if you need only the defaultLogger, you don't need instantiating an ActionLogger object.
    ///
    /// all public class functions work with this defaultLogger
    ///
    /// - returns: `the static defaultLogger`
    public class func defaultLogger() -> ActionLogger {
        return statics.defaultLogger
    }
    
    // MARK: - DebugPrintable
    public var debugDescription: String {
        get {
            var description: String = "ActionLogger: \(identifier) - logDestinations: \r"
            for logDestination in logDestinations {
                description += "\t \(logDestination.debugDescription)\r"
            }
            
            return description
        }
    }
    
    // MARK: - Setup methods
    /// use this class function to setup the defaultLogger
    ///
    /// for description of parameters see the instance function
    public class func setup(logLevel logLevel: LogLevel = .AllLevels, showDateAndTime: Bool = true, showLogLevel: Bool = true, showFileName: Bool = true, showLineNumber: Bool = true, showFuncName: Bool = true, dateFormatter: NSDateFormatter = ActionLogger.dateFormatterGER, writeToFile: AnyObject? = nil) {
        defaultLogger().setup(logLevel: logLevel, showDateAndTime: showDateAndTime, showLogLevel: showLogLevel, showFileName: showFileName, showLineNumber: showLineNumber, showFuncName: showFuncName, dateFormatter: dateFormatter, writeToFile: writeToFile)
    }
    
    /// use this function to setup properties of the ActionLogger object
    ///
    /// - Parameters:
    ///   - logLevel: setup the outputLogLevel  default = .AllLevels
    ///   - showDateAndTime: shows the date and time in the message default = true
    ///   - showLogLevel: shows the LogLevel of the message default = true
    ///   - showFileName: shows the filename where the message is generated default = true
    ///   - showLineNumber: shows the linenumber in the file where the message is generated (only if showFileName is true)  default = true
    ///   - showFuncName: shows the func name where the message is generated    default = true
    ///   - dateFormatter: the dateFormatter which is used (ActionLogger has implemented dateFormatterGER and dateFormatterUSA, but you can also use your own)  default = ActionLogger.dateFormatterGER
    ///   - writeToFile: a file to which the messages are written
    public func setup(logLevel logLevel: LogLevel = .AllLevels, showDateAndTime: Bool = true,  showLogLevel: Bool = true, showFileName: Bool = true, showLineNumber: Bool = true, showFuncName: Bool = true, dateFormatter: NSDateFormatter = ActionLogger.dateFormatterGER, writeToFile: AnyObject? = nil) {
        outputLogLevel = logLevel;
        
        if let unwrappedWriteToFile : AnyObject = writeToFile {
            // We've been passed a file to use for logging, set up a file logger
            if let logFileDestination: ActionLogFileDestination = ActionLogFileDestination(writeToFile: unwrappedWriteToFile) {
                addLogDestination(logFileDestination)
            }
            else {
                // melde den Fehler
                self.error("could not create ActionLogDestination for \(writeToFile)")
            }
        }
        
        for var logDestination in logDestinations {
            logDestination.outputLogLevel = logLevel
            logDestination.showDateAndTime = showDateAndTime
            logDestination.showLogLevel = showLogLevel
            logDestination.showFileName = showFileName
            if logDestination.showFileName == false && logDestination.showLineNumber == true {
                self.error("showLineNumber cannot set true, if shoefileName is false")
            }
            else {
                logDestination.showLineNumber = showLineNumber
            }
            logDestination.showFuncName = showFuncName
            logDestination.dateFormatter = dateFormatter
        }
    }
    
    /// use this class function to setup the outputLogLevel of the defaultLogger
    ///
    /// for description of parameters see the instance function
    public class func setupLogLevel(logLevel: ActionLogger.LogLevel) {
        defaultLogger().setupLogLevel(logLevel)
    }
    
    /// use this function to setup the outputLogLevel of the ActionLogger object
    ///
    /// - Parameters:
    ///   - logLevel: setup the outputLogLevel
    public func setupLogLevel(logLevel: ActionLogger.LogLevel) {
        outputLogLevel = logLevel;
        
        for var logDestination in logDestinations {
            logDestination.outputLogLevel = outputLogLevel
        }
    }
    
    
    /// use this class function to setup the showDateAndTime property of the defaultLogger
    ///
    /// for description of parameters see the instance function
    public class func setupShowDateAndTime(showDateAndTime: Bool) {
        defaultLogger().setupShowDateAndTime(showDateAndTime)
    }
    
    /// use this function to setup the showDateAndTime property of the ActionLogger object
    ///
    /// - Parameters:
    ///   - showDateAndTime: shows the date and time in the message
    public func setupShowDateAndTime(showDateAndTime: Bool) {
        for var logDestination in logDestinations {
            logDestination.showDateAndTime = showDateAndTime
        }
    }
    
    /// use this class function to setup the showLogLevel property of the defaultLogger
    ///
    /// for description of parameters see the instance function
    public class func setupShowLogLevel(showLogLevel: Bool) {
        defaultLogger().setupShowLogLevel(showLogLevel)
    }
    
    /// use this function to setup the showLogLevel property of the ActionLogger object
    ///
    /// - Parameters:
    ///   - showLogLevel: shows the LogLevel of the message
    public func setupShowLogLevel(showLogLevel: Bool) {
        for var logDestination in logDestinations {
            logDestination.showLogLevel = showLogLevel
        }
    }
    
    /// use this class function to setup the showFileName property of the defaultLogger
    ///
    /// for description of parameters see the instance function
    public class func setupShowFileName(showFileName: Bool) {
        defaultLogger().setupShowFileName(showFileName)
    }
    
    /// use this function to setup the showFileName property of the ActionLogger object
    ///
    /// - Parameters:
    ///   - showFileName: shows the filename where the message is generated
    public func setupShowFileName(showFileName: Bool) {
        for var logDestination in logDestinations {
            logDestination.showFileName = showFileName
            if showFileName == false {
                logDestination.showLineNumber = false
            }
        }
    }
    
    /// use this class function to setup the showFileNumber property of the defaultLogger
    ///
    /// for description of parameters see the instance function
    public class func setupShowLineNumber(showLineNumber: Bool) {
        defaultLogger().setupShowLineNumber(showLineNumber)
    }
    
    /// use this function to setup the showFilenumber property of the ActionLogger object
    ///
    /// - Parameters:
    ///   - showLineNumber: shows the linenumber in the file where the message is generated (only if showFileName is true)
    public func setupShowLineNumber(showLineNumber: Bool) {
        for var logDestination in logDestinations {
            if logDestination.showFileName == true {
                logDestination.showLineNumber = showLineNumber
            }
            else {
                if showLineNumber == true {
                    ActionLogger.error("showLineNumber cannot set true, if showFileName is false")
                }
            }
        }
    }
    
    /// use this class function to setup the showFuncName property of the defaultLogger
    ///
    /// for description of parameters see the instance function
    public class func setupShowFuncName(showFuncName: Bool) {
        defaultLogger().setupShowFuncName(showFuncName)
    }
    
    /// use this function to setup the showFuncName property of the ActionLogger object
    ///
    /// - Parameters:
    ///   - showFuncName: shows the func name where the message is generated
    public func setupShowFuncName(showFuncName: Bool) {
        for var logDestination in logDestinations {
            logDestination.showFuncName = showFuncName
        }
    }
    
    
    /// use this class function to setup the dateFormatter property of the defaultLogger
    ///
    /// for description of parameters see the instance function
    public class func setupDateFormatter(dateFormatter: NSDateFormatter) {
        defaultLogger().setupDateFormatter(dateFormatter)
    }
    
    /// use this function to setup the dateFormatter property of the ActionLogger object
    ///
    /// - Parameters:
    ///   - dateFormatter: the dateFormatter which is used (ActionLogger has implemented dateFormatterGER and dateFormatterUSA, but you can also use your own)
    public func setupDateFormatter(dateFormatter: NSDateFormatter) {
        for var logDestination in logDestinations {
            logDestination.dateFormatter = dateFormatter
        }
    }
    
    /// logs all properties values to the output
    public func logSetupValues() {
        // log the setup values
        var message =   "setupValues for ActionLogger object\n" +
            "ActionLogger Version: \(constants.ActionLoggerVersion)\n" +
            "Identifier          : \(identifier)\n" +
            "outputLogLevel      : \(outputLogLevel.description())\n" +
            "with logDestinations:\n"
        
        for logDestination in logDestinations {
            let typeLongName = _stdlib_getDemangledTypeName(logDestination)
            let tokens = typeLongName.characters.split(isSeparator: { $0 == "." }).map { String($0) }
            let typeName = tokens.last!
            message += "\n" +
                "Type of logDestination: \(typeName)\n" +
                "Identifier            : \(logDestination.identifier)\n" +
                "showLogLevel          : \(logDestination.showLogLevel)\n" +
                "showFileName          : \(logDestination.showFileName)\n" +
                "showLineNumber        : \(logDestination.showLineNumber)\n" +
                "showFuncName          : \(logDestination.showFuncName)\n" +
            "date & time format    : \(logDestination.dateFormatter.dateFormat)\n"
            
            if logDestination.hasFile() {
                message +=
                "writeToFile           : \((logDestination as! ActionLogFileDestination).getLogFileURL())\n"
            }
        }
        message += "\nend of setupValues\n"
        logLine(message, logLevel: LogLevel.Info, functionName: "", fileName: "", lineNumber: 0, withFileLineFunctionInfo: false)
    }
    
    // MARK: - Logging methods
    public class func logLine(logMessage: String, logLevel: LogLevel = .Debug, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, withFileLineFunctionInfo: Bool = true) {
        self.defaultLogger().logLine(logMessage, logLevel: logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, withFileLineFunctionInfo: withFileLineFunctionInfo)
    }
    
    public func logLine(logMessage: String, logLevel: LogLevel = .Debug, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, withFileLineFunctionInfo: Bool = true) {
        let date = NSDate()
        let logDetails = ActionLogDetails(logLevel: logLevel, date: date, logMessage: logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        for logDestination in self.logDestinations {
            logDestination.processLogDetails(logDetails,withFileLineFunctionInfo: withFileLineFunctionInfo)
        }
    }
    
    public class func exec(logLevel: LogLevel = .Debug, closure: () -> () = {}) {
        self.defaultLogger().exec(logLevel, closure: closure)
    }
    
    public func exec(logLevel: LogLevel = .Debug, closure: () -> () = {}) {
        if (!isEnabledForLogLevel(logLevel)) {
            return
        }
        
        closure()
    }
    
    //    func logLogDetails(logDetails: [ActionLogDetails], selectedLogDestination: ActionLogDestinationProtocol? = nil) {
    //        for logDestination in (selectedLogDestination != nil ? [selectedLogDestination!] : logDestinations) {
    //            for logDetail in logDetails {
    //                logDestination.processLogDetails(logDetail,withFileLineFunctionInfo: false)
    //            }
    //        }
    //    }
    
    
    
    // MARK: - Convenience logging methods
    public class func messageOnly(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultLogger().messageOnly(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public func messageOnly(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logLine(logMessage, logLevel: .MessageOnly, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public class func comment(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultLogger().comment(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public func comment(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logLine(logMessage, logLevel: .Comment, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    public class func verbose(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultLogger().verbose(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public func verbose(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logLine(logMessage, logLevel: .Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public class func debug(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultLogger().debug(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public func debug(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logLine(logMessage, logLevel: .Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public class func info(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultLogger().info(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public func info(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logLine(logMessage, logLevel: .Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public class func warning(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultLogger().warning(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public func warning(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logLine(logMessage, logLevel: .Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public class func error(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultLogger().error(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public func error(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logLine(logMessage, logLevel: .Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public class func severe(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultLogger().severe(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public func severe(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logLine(logMessage, logLevel: .Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public class func messageOnlyExec(closure: () -> () = {}) {
        self.defaultLogger().exec(ActionLogger.LogLevel.MessageOnly, closure: closure)
    }
    
    public func messageOnlyExec(closure: () -> () = {}) {
        self.exec(ActionLogger.LogLevel.MessageOnly, closure: closure)
    }
    
    public class func commentExec(closure: () -> () = {}) {
        self.defaultLogger().exec(ActionLogger.LogLevel.Comment, closure: closure)
    }
    
    public func commentExec(closure: () -> () = {}) {
        self.exec(ActionLogger.LogLevel.Comment, closure: closure)
    }
    
    public class func verboseExec(closure: () -> () = {}) {
        self.defaultLogger().exec(ActionLogger.LogLevel.Verbose, closure: closure)
    }
    
    public func verboseExec(closure: () -> () = {}) {
        self.exec(ActionLogger.LogLevel.Verbose, closure: closure)
    }
    
    public class func debugExec(closure: () -> () = {}) {
        self.defaultLogger().exec(ActionLogger.LogLevel.Debug, closure: closure)
    }
    
    public func debugExec(closure: () -> () = {}) {
        self.exec(ActionLogger.LogLevel.Debug, closure: closure)
    }
    
    public class func infoExec(closure: () -> () = {}) {
        self.defaultLogger().exec(ActionLogger.LogLevel.Info, closure: closure)
    }
    
    public func infoExec(closure: () -> () = {}) {
        self.exec(ActionLogger.LogLevel.Info, closure: closure)
    }
    
    public class func warningExec(closure: () -> () = {}) {
        self.defaultLogger().exec(ActionLogger.LogLevel.Warning, closure: closure)
    }
    
    public func warningExec(closure: () -> () = {}) {
        self.exec(ActionLogger.LogLevel.Warning, closure: closure)
    }
    
    public class func errorExec(closure: () -> () = {}) {
        self.defaultLogger().exec(ActionLogger.LogLevel.Error, closure: closure)
    }
    
    public func errorExec(closure: () -> () = {}) {
        self.exec(ActionLogger.LogLevel.Error, closure: closure)
    }
    
    public class func severeExec(closure: () -> () = {}) {
        self.defaultLogger().exec(ActionLogger.LogLevel.Severe, closure: closure)
    }
    
    public func severeExec(closure: () -> () = {}) {
        self.exec(ActionLogger.LogLevel.Severe, closure: closure)
    }
    
    // MARK: - Misc methods
    public func isEnabledForLogLevel (logLevel: ActionLogger.LogLevel) -> Bool {
        return logLevel >= self.outputLogLevel
    }
    
    public func logDestination(identifier: String) -> ActionLogDestinationProtocol? {
        for logDestination in logDestinations {
            if logDestination.identifier == identifier {
                return logDestination
            }
        }
        return nil
    }
    
    public func getLogDestinations() -> [ActionLogDestinationProtocol] {
        return logDestinations
    }
    
    public func addLogDestination(logDestination: ActionLogDestinationProtocol) -> Bool {
        let existingLogDestination: ActionLogDestinationProtocol? = self.logDestination(logDestination.identifier)
        if existingLogDestination != nil {
            return false
        }
        logDestinations.append(logDestination)
        return true
    }
    
    public func removeLogDestination(logDestination: ActionLogDestinationProtocol) {
        removeLogDestination(logDestination.identifier)
    }
    
    public func removeLogDestination(identifier: String) {
        logDestinations = logDestinations.filter({$0.identifier != identifier})
    }
    
}


// Implement Comparable for ActionLogger.LogLevel
public func < (lhs:ActionLogger.LogLevel, rhs:ActionLogger.LogLevel) -> Bool {
    return lhs.rawValue < rhs.rawValue
}


// MARK: - ActionLogXcodeColorProfile
/// ColorProfile which is used with the XcodeColor plugin for coloring Xcode console outputs
struct ActionLogXcodeColorProfile {
    
    var fg_Red:UInt8 = 0
    var fg_Green: UInt8 = 0
    var fg_Blue: UInt8 = 0
    
    var fg_code: String = ""
    
    var bg_Red:UInt8 = 255
    var bg_Green: UInt8 = 255
    var bg_Blue: UInt8 = 255
    
    var bg_code: String = ""
    
    let fg_reset_code: String = "\u{001B}[fg;"
    let bg_reset_code: String = "\u{001B}[bg;"
    let all_reset_code: String = "\u{001B}[;"
    
    let xcodeColorEscape = "\u{001B}["
    
    init (fg_Red: UInt8=0,fg_Green: UInt8=0,fg_Blue: UInt8=0,bg_Red: UInt8=255,bg_Green: UInt8=255,bg_Blue: UInt8=255) {
        self.fg_Red = fg_Red; self.fg_Green = fg_Green; self.fg_Blue = fg_Blue
        self.bg_Red = bg_Red; self.bg_Green = bg_Green; self.bg_Blue = bg_Blue
        
        self.fg_code = xcodeColorEscape + (NSString(format: "fg%d,%d,%d;", self.fg_Red,self.fg_Green,self.fg_Blue) as String)
        self.bg_code = xcodeColorEscape + (NSString(format: "bg%d,%d,%d;", self.bg_Red,self.bg_Green,self.bg_Blue) as String)
        
    }
    
    #if os(OSX)
    
    init(foregroundColor fg_color: NSColor, backgroundColor bg_color: NSColor) {
        var fg_red: CGFloat = 0, fg_green: CGFloat = 0, fg_blue: CGFloat = 0
        var bg_red: CGFloat = 0, bg_green: CGFloat = 0, bg_blue: CGFloat = 0
        var alpha: CGFloat = 0
        let fg_c = fg_color.colorUsingColorSpace(NSColorSpace.deviceRGBColorSpace())
        fg_c!.getRed(&fg_red, green: &fg_green, blue: &fg_blue, alpha: &alpha)
        let bg_c = bg_color.colorUsingColorSpace(NSColorSpace.deviceRGBColorSpace())
        bg_c!.getRed(&bg_red, green: &bg_green, blue: &bg_blue, alpha: &alpha)
        
        self.fg_Red = UInt8(fg_red * 255.0); self.fg_Green = UInt8(fg_green * 255.0); self.fg_Blue = UInt8(fg_blue * 255.0)
        self.bg_Red = UInt8(bg_red * 255.0); self.bg_Green = UInt8(bg_green * 255.0); self.bg_Blue = UInt8(bg_blue * 255.0)
        
        self.fg_code = xcodeColorEscape + (NSString(format: "fg%d,%d,%d;", self.fg_Red,self.fg_Green,self.fg_Blue) as String)
        self.bg_code = xcodeColorEscape + (NSString(format: "bg%d,%d,%d;", self.bg_Red,self.bg_Green,self.bg_Blue) as String)
        
    }
    
    #endif
    
    
    #if os(iOS)
    
    init(foregroundColor fg_color: UIColor, backgroundColor bg_color: UIColor) {
    var fg_red: CGFloat = 0, fg_green: CGFloat = 0, fg_blue: CGFloat = 0
    var bg_red: CGFloat = 0, bg_green: CGFloat = 0, bg_blue: CGFloat = 0
    var alpha: CGFloat = 0
    fg_color.getRed(&fg_red, green: &fg_green, blue: &fg_blue, alpha: &alpha)
    bg_color.getRed(&bg_red, green: &bg_green, blue: &bg_blue, alpha: &alpha)
    
    self.fg_Red = UInt8(fg_red * 255.0); self.fg_Green = UInt8(fg_green * 255.0); self.fg_Blue = UInt8(fg_blue * 255.0)
    self.bg_Red = UInt8(bg_red * 255.0); self.bg_Green = UInt8(bg_green * 255.0); self.bg_Blue = UInt8(bg_blue * 255.0)
    
    self.fg_code = xcodeColorEscape + (NSString(format: "fg%d,%d,%d;", self.fg_Red,self.fg_Green,self.fg_Blue) as String)
    self.bg_code = xcodeColorEscape + (NSString(format: "bg%d,%d,%d;", self.bg_Red,self.bg_Green,self.bg_Blue) as String)
    
    }
    
    #endif
    
    mutating func buildForegroundCode() {
        self.fg_code = xcodeColorEscape + (NSString(format: "fg%d,%d,%d;", self.fg_Red,self.fg_Green,self.fg_Blue) as String)
    }
    
    mutating func buildBackgroundCode() {
        self.bg_code = xcodeColorEscape + (NSString(format: "bg%d,%d,%d;", self.bg_Red,self.bg_Green,self.bg_Blue) as String)
    }
    
}

// MARK: - common functions
public func preProcessLogDetails(logDetails: ActionLogDetails, showDateAndTime: Bool, showLogLevel: Bool, showFileName: Bool, showLineNumber: Bool, showFuncName: Bool, dateFormatter: NSDateFormatter,
    withFileLineFunctionInfo: Bool = true) -> String {
        // create extended details
        var extendedDetails: String = ""
        if showLogLevel && (logDetails.logLevel > .MessageOnly) {
            extendedDetails += "[" + logDetails.logLevel.description() + "] "
        }
        
        if withFileLineFunctionInfo {
            // showLineNumber is only relevant with showFileName
            if showFileName {
                let url = NSURL(fileURLWithPath:logDetails.fileName)
                extendedDetails += "[" + url.lastPathComponent! + (showLineNumber ? ":" + String(logDetails.lineNumber) : "") + "] "
            }
            
            if showFuncName {
                extendedDetails += "\(logDetails.functionName) "
            }
        }
        let formattedDate: String = dateFormatter.stringFromDate(logDetails.date)
        
        var logMessage = logDetails.logMessage
        
        if logDetails.logLevel == ActionLogger.LogLevel.Comment {
            logMessage = "// " + logMessage
        }
        
        if showDateAndTime == true {
            return  "\(formattedDate) \(extendedDetails): \(logMessage)\n"
        }
        else {
            return  "\(extendedDetails): \(logMessage)\n"
        }
}

// MARK: - ActionLogDestinationProtocol
/// - Protocol for output classes to conform to
public protocol ActionLogDestinationProtocol: CustomDebugStringConvertible {
    var identifier: String {get set}
    var showDateAndTime: Bool {get set}
    var showLogLevel: Bool {get set}
    var showFileName: Bool {get set}
    var showLineNumber: Bool {get set}
    var showFuncName: Bool {get set}
    var dateFormatter: NSDateFormatter {get set}
    var outputLogLevel: ActionLogger.LogLevel {get set}
    
    func processLogDetails(logDetails: ActionLogDetails, withFileLineFunctionInfo: Bool)
    func isEnabledForLogLevel(logLevel: ActionLogger.LogLevel) -> Bool
    func hasFile() -> Bool
    // color enhancement
    func isEnabledForColor() -> Bool
}

// MARK: - ActionLogConsoleDestination
/// - A standard log destination that outputs log details to the console
public class ActionLogConsoleDestination : ActionLogDestinationProtocol, CustomDebugStringConvertible {
    //    var owner: ActionLogger
    public var identifier: String
    
    public var showDateAndTime: Bool = true
    public var showLogLevel: Bool = true
    public var showFileName: Bool = true
    public var showLineNumber: Bool = true
    public var showFuncName: Bool = true
    public var dateFormatter = ActionLogger.dateFormatterGER
    public var outputLogLevel: ActionLogger.LogLevel = .AllLevels
    
    // color enhancement
    var colorProfiles = Dictionary<ActionLogger.LogLevel,ActionLogXcodeColorProfile>()
    
    
    init(identifier: String = "") {
        //        self.owner = owner
        self.identifier = identifier
        
        // color enhancement
        if isEnabledForColor() {
            // setting default color values
            #if os(OSX)
                self.colorProfiles[.AllLevels]    = ActionLogXcodeColorProfile(foregroundColor: NSColor.whiteColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.MessageOnly]  = ActionLogXcodeColorProfile(foregroundColor: NSColor.lightGrayColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Comment]      = ActionLogXcodeColorProfile(foregroundColor: NSColor.grayColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Verbose]      = ActionLogXcodeColorProfile(foregroundColor: NSColor.darkGrayColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Info]         = ActionLogXcodeColorProfile(foregroundColor: NSColor.blueColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Debug]        = ActionLogXcodeColorProfile(foregroundColor: NSColor.greenColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Warning]      = ActionLogXcodeColorProfile(foregroundColor: NSColor.orangeColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Error]        = ActionLogXcodeColorProfile(foregroundColor: NSColor.redColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Severe]       = ActionLogXcodeColorProfile(foregroundColor: NSColor.magentaColor(),backgroundColor: NSColor.whiteColor())
            #endif
            
            #if os(iOS)
                self.colorProfiles[.AllLevels]    = ActionLogXcodeColorProfile(foregroundColor: UIColor.whiteColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.MessageOnly]  = ActionLogXcodeColorProfile(foregroundColor: UIColor.lightGrayColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Comment]      = ActionLogXcodeColorProfile(foregroundColor: UIColor.grayColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Verbose]      = ActionLogXcodeColorProfile(foregroundColor: UIColor.darkGrayColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Info]         = ActionLogXcodeColorProfile(foregroundColor: UIColor.blueColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Debug]        = ActionLogXcodeColorProfile(foregroundColor: UIColor.greenColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Warning]      = ActionLogXcodeColorProfile(foregroundColor: UIColor.orangeColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Error]        = ActionLogXcodeColorProfile(foregroundColor: UIColor.redColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Severe]       = ActionLogXcodeColorProfile(foregroundColor: UIColor.magentaColor(),backgroundColor: UIColor.whiteColor())
            #endif
        }
    }
    
    public func setDefaultLogLevelColors() {
        // color enhancement
        if isEnabledForColor() {
            // setting default color values
            #if os(OSX)
                self.colorProfiles[.AllLevels]    = ActionLogXcodeColorProfile(foregroundColor: NSColor.whiteColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.MessageOnly]  = ActionLogXcodeColorProfile(foregroundColor: NSColor.lightGrayColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Comment]      = ActionLogXcodeColorProfile(foregroundColor: NSColor.grayColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Verbose]      = ActionLogXcodeColorProfile(foregroundColor: NSColor.darkGrayColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Info]         = ActionLogXcodeColorProfile(foregroundColor: NSColor.blueColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Debug]        = ActionLogXcodeColorProfile(foregroundColor: NSColor.greenColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Warning]      = ActionLogXcodeColorProfile(foregroundColor: NSColor.orangeColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Error]        = ActionLogXcodeColorProfile(foregroundColor: NSColor.redColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Severe]       = ActionLogXcodeColorProfile(foregroundColor: NSColor.magentaColor(),backgroundColor: NSColor.whiteColor())
            #endif
            
            #if os(iOS)
                self.colorProfiles[.AllLevels]    = ActionLogXcodeColorProfile(foregroundColor: UIColor.whiteColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.MessageOnly]  = ActionLogXcodeColorProfile(foregroundColor: UIColor.lightGrayColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Comment]      = ActionLogXcodeColorProfile(foregroundColor: UIColor.grayColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Verbose]      = ActionLogXcodeColorProfile(foregroundColor: UIColor.darkGrayColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Info]         = ActionLogXcodeColorProfile(foregroundColor: UIColor.blueColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Debug]        = ActionLogXcodeColorProfile(foregroundColor: UIColor.greenColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Warning]      = ActionLogXcodeColorProfile(foregroundColor: UIColor.orangeColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Error]        = ActionLogXcodeColorProfile(foregroundColor: UIColor.redColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Severe]       = ActionLogXcodeColorProfile(foregroundColor: UIColor.magentaColor(),backgroundColor: UIColor.whiteColor())
            #endif
        }
    }
    
    public func processLogDetails(logDetails: ActionLogDetails, withFileLineFunctionInfo: Bool = true) {
        var fullLogMessage = preProcessLogDetails(logDetails, showDateAndTime: showDateAndTime, showLogLevel: showLogLevel, showFileName: showFileName, showLineNumber: showLineNumber, showFuncName: showFuncName, dateFormatter: dateFormatter, withFileLineFunctionInfo: withFileLineFunctionInfo)
        
        // color enhancement
        if let cp = self.colorProfiles[logDetails.logLevel] {
            fullLogMessage = cp.fg_code + cp.bg_code + fullLogMessage + cp.all_reset_code
        }
        
        // print it, only if the LogDestination should print this
        if isEnabledForLogLevel(logDetails.logLevel) {
            print(fullLogMessage, terminator: "")
        }
    }
    
    // MARK: - Misc methods
    public func isEnabledForLogLevel (logLevel: ActionLogger.LogLevel) -> Bool {
        return logLevel >= self.outputLogLevel
    }
    
    // color enhancement
    public func isEnabledForColor() -> Bool {
        let dict = NSProcessInfo.processInfo().environment
        
        if let env = dict["XcodeColors"] as String! {
            return env == "YES"
        }
        return false
    }
    
    public func hasFile() -> Bool {
        return false
    }
    
    // MARK: - DebugPrintable
    public var debugDescription: String {
        get {
            return "ActionLogConsoleDestination: \(identifier) - LogLevel: \(outputLogLevel.description()) showLogLevel: \(showLogLevel) showFileName: \(showFileName) showLineNumber: \(showLineNumber) date & time format: \(dateFormatter.dateFormat)"
        }
    }
    
    // color enhancement
    // MARK: - color enhancement
    public func setLogColors(foregroundRed fg_red: UInt8 = 0, foregroundGreen fg_green: UInt8 = 0, foregroundBlue fg_blue: UInt8 = 0, backgroundRed bg_red: UInt8 = 255, backgroundGreen bg_green: UInt8 = 255, backgroundBlue bg_blue: UInt8 = 255, forLogLevel logLevel: ActionLogger.LogLevel) {
        if var cp = self.colorProfiles[logLevel] {
            cp.fg_Red = fg_red; cp.fg_Green = fg_green; cp.fg_Blue = fg_blue
            cp.bg_Red = bg_red; cp.bg_Green = bg_green; cp.bg_Blue = bg_blue
            cp.buildForegroundCode()
            cp.buildBackgroundCode()
            self.colorProfiles[logLevel] = cp
        }
    }
    
    /*! using setLogColors:
    setLogColor(foregroundRed:0,foregroundGreen:0,foregroundBlue:0,forLogLevel:.Verbose)        means: resetForegroundColor of logLevel .Verbose to black
    setLogColor(backgroundRed:255,backgroundGreen:255,backgroundBlue:255,forLogLevel:.Debug)    means: resetBackgroundColor of logLevel .Debug   to white
    */
    
    public func resetAllLogColors() {
        for (logLevel, var colorProfile) in colorProfiles {
            colorProfile.fg_Red = 0; colorProfile.fg_Green = 0; colorProfile.fg_Blue = 0
            colorProfile.bg_Red = 255; colorProfile.bg_Green = 255; colorProfile.bg_Blue = 255
            colorProfile.buildForegroundCode()
            colorProfile.buildBackgroundCode()
            self.colorProfiles[logLevel] = colorProfile
        }
    }
    
    #if os(OSX)
    
    public func setForegroundColor(color: NSColor, forLogLevel logLevel: ActionLogger.LogLevel) {
        var fg_red: CGFloat = 0, fg_green: CGFloat = 0, fg_blue: CGFloat = 0
        var alpha: CGFloat = 0
        let c = color.colorUsingColorSpace(NSColorSpace.deviceRGBColorSpace())
        c!.getRed(&fg_red, green: &fg_green, blue: &fg_blue, alpha: &alpha)
        
        if var cp = self.colorProfiles[logLevel] {
            cp.fg_Red = UInt8(fg_red * 255.0); cp.fg_Green = UInt8(fg_green * 255.0); cp.fg_Blue = UInt8(fg_blue * 255.0)
            cp.buildForegroundCode()
            cp.buildBackgroundCode()
            self.colorProfiles[logLevel] = cp
        }
    }
    
    
    public func setBackgroundColor(color: NSColor, forLogLevel logLevel: ActionLogger.LogLevel) {
        var bg_red: CGFloat = 0, bg_green: CGFloat = 0, bg_blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        let c = color.colorUsingColorSpace(NSColorSpace.deviceRGBColorSpace())
        c!.getRed(&bg_red, green: &bg_green, blue: &bg_blue, alpha: &alpha)
        
        if var cp = self.colorProfiles[logLevel] {
            cp.bg_Red = UInt8(bg_red * 255.0); cp.bg_Green = UInt8(bg_green * 255.0); cp.bg_Blue = UInt8(bg_blue * 255.0)
            cp.buildForegroundCode()
            cp.buildBackgroundCode()
            self.colorProfiles[logLevel] = cp
        }
    }
    
    #endif
    
    #if os(iOS)
    
    public func setForegroundColor(color: UIColor, forLogLevel logLevel: ActionLogger.LogLevel) {
    var fg_red: CGFloat = 0, fg_green: CGFloat = 0, fg_blue: CGFloat = 0
    var alpha: CGFloat = 0
    color.getRed(&fg_red, green: &fg_green, blue: &fg_blue, alpha: &alpha)
    
    if var cp = self.colorProfiles[logLevel] {
    cp.fg_Red = UInt8(fg_red * 255.0); cp.fg_Green = UInt8(fg_green * 255.0); cp.fg_Blue = UInt8(fg_blue * 255.0)
    cp.buildForegroundCode()
    cp.buildBackgroundCode()
    self.colorProfiles[logLevel] = cp
    }
    }
    
    
    public func setBackgroundColor(color: UIColor, forLogLevel logLevel: ActionLogger.LogLevel) {
    var bg_red: CGFloat = 0, bg_green: CGFloat = 0, bg_blue: CGFloat = 0
    var alpha: CGFloat = 0
    
    color.getRed(&bg_red, green: &bg_green, blue: &bg_blue, alpha: &alpha)
    
    if var cp = self.colorProfiles[logLevel] {
    cp.bg_Red = UInt8(bg_red * 255.0); cp.bg_Green = UInt8(bg_green * 255.0); cp.bg_Blue = UInt8(bg_blue * 255.0)
    cp.buildForegroundCode()
    cp.buildBackgroundCode()
    self.colorProfiles[logLevel] = cp
    }
    }
    
    #endif
}

// MARK: - ActionLogFileDestination
/// - A standard log destination that outputs log details to a file
public class ActionLogFileDestination : ActionLogDestinationProtocol, CustomDebugStringConvertible {
    //    var owner: ActionLogger
    public var identifier: String = ""
    
    public var showDateAndTime: Bool = true
    public var showLogLevel: Bool = true
    public var showFileName: Bool = true
    public var showLineNumber: Bool = true
    public var showFuncName: Bool = true
    public var dateFormatter = ActionLogger.dateFormatterGER
    public var outputLogLevel: ActionLogger.LogLevel = .AllLevels
    
    private var writeToFileURL : NSURL? = nil {
        didSet {
            openFile()
        }
    }
    private var logFileHandle: NSFileHandle? = nil
    
    init?(writeToFile: AnyObject) {
        
        if writeToFile is NSString {
            writeToFileURL = NSURL.fileURLWithPath(writeToFile as! String)
            self.identifier = writeToFile as! String
        }
        else if writeToFile is NSURL {
            writeToFileURL = writeToFile as? NSURL
            if !writeToFileURL!.fileURL
            {
                ActionLogger.defaultLogger().error("no fileURL is given!")
                return nil
            }
            else {
                self.identifier = writeToFileURL!.absoluteString
            }
        }
        else {
            ActionLogger.defaultLogger().error("unable to open file: \"\(writeToFile as! String)\"")
            writeToFileURL = nil
            return nil
        }
        
        if !openFile() {
            ActionLogger.defaultLogger().error("unable to open file: \"\(writeToFileURL)\"")
            return nil
        }
        closeFile()
    }
    
    deinit {
        // close file stream if open
        closeFile()
    }
    
    // MARK: - Logging methods
    public func processLogDetails(logDetails: ActionLogDetails, withFileLineFunctionInfo: Bool = true) {
        let fullLogMessage = preProcessLogDetails(logDetails, showDateAndTime: showDateAndTime, showLogLevel: showLogLevel, showFileName: showFileName, showLineNumber: showLineNumber, showFuncName: showFuncName,  dateFormatter: dateFormatter, withFileLineFunctionInfo: withFileLineFunctionInfo)
        
        // print it, only if the LogDestination should print this
        if isEnabledForLogLevel(logDetails.logLevel) {
            if let encodedData = fullLogMessage.dataUsingEncoding(NSUTF8StringEncoding) {
                reopenFile()
                logFileHandle?.writeData(encodedData)
                closeFile()
            }
        }
    }
    
    public func getLogFileName() -> String {
        return writeToFileURL!.lastPathComponent!
    }
    
    public func getLogFileURL() -> String {
        return writeToFileURL!.absoluteString
    }
    
    
    // MARK: - Misc methods
    public func isEnabledForLogLevel (logLevel: ActionLogger.LogLevel) -> Bool {
        return logLevel >= self.outputLogLevel
    }
    
    public func isEnabledForColor() -> Bool {
        return false
    }
    
    public func hasFile() -> Bool {
        return true
    }
    
    private func openFile() -> Bool {
        if logFileHandle != nil {
            closeFile()
        }
        
        if let unwrappedWriteToFileURL = writeToFileURL {
            if let path = unwrappedWriteToFileURL.path {
                NSFileManager.defaultManager().createFileAtPath(path, contents: nil, attributes: nil)
                var fileError : NSError? = nil
                do {
                    logFileHandle = try NSFileHandle(forWritingToURL: unwrappedWriteToFileURL)
                } catch let error as NSError {
                    fileError = error
                    logFileHandle = nil
                }
                if logFileHandle == nil {
                    ActionLogger.defaultLogger().logLine("Attempt to open log file for writing failed: \(fileError?.localizedDescription)", logLevel: .Error, withFileLineFunctionInfo: false)
                    return false
                }
                else {
                    ActionLogger.defaultLogger().logLine("ActionLogger writing log to: \(unwrappedWriteToFileURL)", logLevel: .Info, withFileLineFunctionInfo: false)
                    return true
                }
            }
        }
        return false
    }
    
    private func reopenFile() -> Bool {
        if logFileHandle != nil {
            closeFile()
        }
        
        if let unwrappedWriteToFileURL = writeToFileURL {
            if let _ = unwrappedWriteToFileURL.path {
                var fileError : NSError? = nil
                do {
                    logFileHandle = try NSFileHandle(forWritingToURL: unwrappedWriteToFileURL)
                } catch let error as NSError {
                    fileError = error
                    logFileHandle = nil
                }
                if logFileHandle == nil {
                    ActionLogger.defaultLogger().logLine("Attempt to open log file for writing failed: \(fileError?.localizedDescription)", logLevel: .Error, withFileLineFunctionInfo: false)
                    return false
                }
                else {
                    logFileHandle?.seekToEndOfFile()
                    return true
                }
            }
        }
        return false
    }
    
    
    private func closeFile() {
        logFileHandle?.closeFile()
        logFileHandle = nil
    }
    
    // MARK: - DebugPrintable
    public var debugDescription: String {
        get {
            return "ActionLogFileDestination: \(identifier) - LogLevel: \(outputLogLevel.description()) showLogLevel: \(showLogLevel) showFileName: \(showFileName) showLineNumber: \(showLineNumber) date & time format: \(dateFormatter.dateFormat)"
        }
    }
}

// color enhancement
// MARK: - ActionLogTextViewColorProfile
/// ColorProfile used with (NS/UI)TextView controls for coloring text outputs
struct ActionLogTextViewColorProfile {
    
    #if os(OSX)
    var foregroundColor: NSColor = NSColor.blackColor()
    var backgroundColor: NSColor = NSColor.whiteColor()
    #endif
    
    #if os(iOS)
    var foregroundColor: UIColor = UIColor.blackColor()
    var backgroundColor: UIColor = UIColor.whiteColor()
    #endif
    
    #if os(OSX)
    init(foregroundColor fg_color: NSColor, backgroundColor bg_color: NSColor) {
        self.foregroundColor = fg_color
        self.backgroundColor = bg_color
    }
    #endif
    
    #if os(iOS)
    init(foregroundColor fg_color: UIColor, backgroundColor bg_color: UIColor) {
    self.foregroundColor = fg_color
    self.backgroundColor = bg_color
    }
    #endif

}

// MARK: - ActionLogTextViewDestination
/// - A log destination that outputs log details to a NSTextView
public class ActionLogTextViewDestination : ActionLogDestinationProtocol, CustomDebugStringConvertible {
    /// the TextView
    #if os(OSX)
    public var textView: NSTextView
    #endif
    
    #if os(iOS)
    public var textView: UITextView
    #endif
    
    public var identifier: String
    
    public var showDateAndTime: Bool = true
    public var showLogLevel: Bool = true
    public var showFileName: Bool = true
    public var showLineNumber: Bool = true
    public var showFuncName: Bool = true
    public var dateFormatter = ActionLogger.dateFormatterGER
    public var outputLogLevel: ActionLogger.LogLevel = .AllLevels
    
    // color enhancement
    var colorProfiles = Dictionary<ActionLogger.LogLevel,ActionLogTextViewColorProfile>()
    
    
    #if os(OSX)
    init(identifier: String = "", textView: NSTextView) {
        self.identifier = identifier
        self.textView = textView
        
        // color enhancement
        if isEnabledForColor() {
            // setting default color values
            self.colorProfiles[.AllLevels]    = ActionLogTextViewColorProfile(foregroundColor: NSColor.whiteColor(),backgroundColor: NSColor.whiteColor())
            self.colorProfiles[.MessageOnly]  = ActionLogTextViewColorProfile(foregroundColor: NSColor.lightGrayColor(),backgroundColor: NSColor.whiteColor())
            self.colorProfiles[.Comment]      = ActionLogTextViewColorProfile(foregroundColor: NSColor.grayColor(),backgroundColor: NSColor.whiteColor())
            self.colorProfiles[.Verbose]      = ActionLogTextViewColorProfile(foregroundColor: NSColor.darkGrayColor(),backgroundColor: NSColor.whiteColor())
            self.colorProfiles[.Info]         = ActionLogTextViewColorProfile(foregroundColor: NSColor.blueColor(),backgroundColor: NSColor.whiteColor())
            self.colorProfiles[.Debug]        = ActionLogTextViewColorProfile(foregroundColor: NSColor.greenColor(),backgroundColor: NSColor.whiteColor())
            self.colorProfiles[.Warning]      = ActionLogTextViewColorProfile(foregroundColor: NSColor.orangeColor(),backgroundColor: NSColor.whiteColor())
            self.colorProfiles[.Error]        = ActionLogTextViewColorProfile(foregroundColor: NSColor.redColor(),backgroundColor: NSColor.whiteColor())
            self.colorProfiles[.Severe]       = ActionLogTextViewColorProfile(foregroundColor: NSColor.magentaColor(),backgroundColor: NSColor.whiteColor())
        }
    }
    #endif
    
    #if os(iOS)
    init(identifier: String = "", textView: UITextView) {
        self.identifier = identifier
        self.textView = textView
        //        self.textView.delegate = self as! NSTextViewDelegate

        // color enhancement
        if isEnabledForColor() {
        // setting default color values
    
        #if os(iOS)
        self.colorProfiles[.AllLevels]    = ActionLogTextViewColorProfile(foregroundColor: UIColor.whiteColor(),backgroundColor: UIColor.whiteColor())
        self.colorProfiles[.MessageOnly]  = ActionLogTextViewColorProfile(foregroundColor: UIColor.lightGrayColor(),backgroundColor: UIColor.whiteColor())
        self.colorProfiles[.Comment]      = ActionLogTextViewColorProfile(foregroundColor: UIColor.grayColor(),backgroundColor: UIColor.whiteColor())
        self.colorProfiles[.Verbose]      = ActionLogTextViewColorProfile(foregroundColor: UIColor.darkGrayColor(),backgroundColor: UIColor.whiteColor())
        self.colorProfiles[.Info]         = ActionLogTextViewColorProfile(foregroundColor: UIColor.blueColor(),backgroundColor: UIColor.whiteColor())
        self.colorProfiles[.Debug]        = ActionLogTextViewColorProfile(foregroundColor: UIColor.greenColor(),backgroundColor: UIColor.whiteColor())
        self.colorProfiles[.Warning]      = ActionLogTextViewColorProfile(foregroundColor: UIColor.orangeColor(),backgroundColor: UIColor.whiteColor())
        self.colorProfiles[.Error]        = ActionLogTextViewColorProfile(foregroundColor: UIColor.redColor(),backgroundColor: UIColor.whiteColor())
        self.colorProfiles[.Severe]       = ActionLogTextViewColorProfile(foregroundColor: UIColor.magentaColor(),backgroundColor: UIColor.whiteColor())
        #endif
        }
    }
    #endif
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setDefaultLogLevelColors() {
        // color enhancement
        if isEnabledForColor() {
            // setting default color values
            #if os(OSX)
                self.colorProfiles[.AllLevels]    = ActionLogTextViewColorProfile(foregroundColor: NSColor.whiteColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.MessageOnly]  = ActionLogTextViewColorProfile(foregroundColor: NSColor.lightGrayColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Comment]      = ActionLogTextViewColorProfile(foregroundColor: NSColor.grayColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Verbose]      = ActionLogTextViewColorProfile(foregroundColor: NSColor.darkGrayColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Info]         = ActionLogTextViewColorProfile(foregroundColor: NSColor.blueColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Debug]        = ActionLogTextViewColorProfile(foregroundColor: NSColor.greenColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Warning]      = ActionLogTextViewColorProfile(foregroundColor: NSColor.orangeColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Error]        = ActionLogTextViewColorProfile(foregroundColor: NSColor.redColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Severe]       = ActionLogTextViewColorProfile(foregroundColor: NSColor.magentaColor(),backgroundColor: NSColor.whiteColor())
            #endif
            
            #if os(iOS)
                self.colorProfiles[.AllLevels]    = ActionLogTextViewColorProfile(foregroundColor: UIColor.whiteColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.MessageOnly]  = ActionLogTextViewColorProfile(foregroundColor: UIColor.lightGrayColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Comment]      = ActionLogTextViewColorProfile(foregroundColor: UIColor.grayColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Verbose]      = ActionLogTextViewColorProfile(foregroundColor: UIColor.darkGrayColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Info]         = ActionLogTextViewColorProfile(foregroundColor: UIColor.blueColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Debug]        = ActionLogTextViewColorProfile(foregroundColor: UIColor.greenColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Warning]      = ActionLogTextViewColorProfile(foregroundColor: UIColor.orangeColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Error]        = ActionLogTextViewColorProfile(foregroundColor: UIColor.redColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Severe]       = ActionLogTextViewColorProfile(foregroundColor: UIColor.magentaColor(),backgroundColor: UIColor.whiteColor())
            #endif
        }
    }
    
    public func processLogDetails(logDetails: ActionLogDetails, withFileLineFunctionInfo: Bool = true) {
        let fullLogMessage = preProcessLogDetails(logDetails, showDateAndTime: showDateAndTime, showLogLevel: showLogLevel, showFileName: showFileName, showLineNumber: showLineNumber, showFuncName: showFuncName, dateFormatter: dateFormatter, withFileLineFunctionInfo: withFileLineFunctionInfo)
        
        let textViewMessage = NSMutableAttributedString(string: fullLogMessage)
        let messageRange = NSRange.init(location: 0, length: textViewMessage.length)
        
        // color enhancement
        if let cp = self.colorProfiles[logDetails.logLevel] {
            // set fore- and backgroundColor
            textViewMessage.addAttribute(NSForegroundColorAttributeName, value: cp.foregroundColor, range: messageRange)
            textViewMessage.addAttribute(NSBackgroundColorAttributeName, value: cp.backgroundColor, range: messageRange)
        }
        
        // print it, only if the LogDestination should print this
        if isEnabledForLogLevel(logDetails.logLevel) {
            #if os(OSX)
                textView.textStorage!.appendAttributedString(textViewMessage)
            #endif

            #if os(iOS)
                textView.textStorage.appendAttributedString(textViewMessage)
            #endif
        }
    }
    
    // MARK: - Misc methods
    public func isEnabledForLogLevel (logLevel: ActionLogger.LogLevel) -> Bool {
        return logLevel >= self.outputLogLevel
    }
    
    // color enhancement
    public func isEnabledForColor() -> Bool {
        // is allways enabled for this Destination
        return true
    }
    
    public func hasFile() -> Bool {
        return false
    }
    
    // MARK: - DebugPrintable
    public var debugDescription: String {
        get {
            return "ActionLogTextViewDestination: \(identifier) - LogLevel: \(outputLogLevel.description()) showLogLevel: \(showLogLevel) showFileName: \(showFileName) showLineNumber: \(showLineNumber) date & time format: \(dateFormatter.dateFormat)"
        }
    }
    
    // color enhancement
    public func setLogColors(foregroundRed fg_red: UInt8 = 0, foregroundGreen fg_green: UInt8 = 0, foregroundBlue fg_blue: UInt8 = 0, backgroundRed bg_red: UInt8 = 255, backgroundGreen bg_green: UInt8 = 255, backgroundBlue bg_blue: UInt8 = 255, forLogLevel logLevel: ActionLogger.LogLevel) {
        if var cp = self.colorProfiles[logLevel] {
            let fg_color = CIColor(red: CGFloat(fg_red)/255.0, green: CGFloat(fg_green)/255.0, blue: CGFloat(fg_blue)/255.0)
            #if os(OSX)
                cp.foregroundColor = NSColor(CIColor: fg_color)
            #endif
            #if os(iOS)
                cp.foregroundColor = UIColor(CIColor: fg_color)
            #endif
            let bg_color = CIColor(red: CGFloat(bg_red)/255.0, green: CGFloat(bg_green)/255.0, blue: CGFloat(bg_blue)/255.0)
            #if os(OSX)
                cp.backgroundColor = NSColor(CIColor: bg_color)
            #endif
            #if os(iOS)
                cp.backgroundColor = UIColor(CIColor: bg_color)
            #endif
            self.colorProfiles[logLevel] = cp
        }
    }
    
    public func resetAllLogColors() {
        for (logLevel, var colorProfile) in colorProfiles {
            
            #if os(OSX)
                colorProfile.foregroundColor = NSColor.blackColor()
                colorProfile.backgroundColor = NSColor.whiteColor()
            #endif
            
            #if os(iOS)
                colorProfile.foregroundColor = UIColor.blackColor()
                colorProfile.backgroundColor = UIColor.whiteColor()
            #endif
            
            self.colorProfiles[logLevel] = colorProfile
        }
    }
    
    #if os(OSX)
    public func setForegroundColor(color: NSColor, forLogLevel logLevel: ActionLogger.LogLevel) {
        if var cp = self.colorProfiles[logLevel] {
            cp.foregroundColor = color
            self.colorProfiles[logLevel] = cp
        }
    }
    
    public func setBackgroundColor(color: NSColor, forLogLevel logLevel: ActionLogger.LogLevel) {
        if var cp = self.colorProfiles[logLevel] {
            cp.backgroundColor = color
            self.colorProfiles[logLevel] = cp
        }
    }
    #endif
    
    #if os(iOS)
    public func setForegroundColor(color: UIColor, forLogLevel logLevel: ActionLogger.LogLevel) {
        if var cp = self.colorProfiles[logLevel] {
        cp.foregroundColor = color
        self.colorProfiles[logLevel] = cp
        }
    }
    
    public func setBackgroundColor(color: UIColor, forLogLevel logLevel: ActionLogger.LogLevel) {
        if var cp = self.colorProfiles[logLevel] {
        cp.backgroundColor = color
        self.colorProfiles[logLevel] = cp
        }
    }
    #endif
}

// some usefull extensions from
// NSScanner+Swift.swift
// A set of Swift-idiomatic methods for NSScanner
//
// (c) 2015 Nate Cook, licensed under the MIT license

extension NSScanner {
    
    /// Returns a string, scanned until a character from a given character set are encountered, or the remainder of the scanner's string. Returns `nil` if the scanner is already `atEnd`.
    func scanUpToCharactersFromSet(set: NSCharacterSet) -> String? {
        var value: NSString? = ""
        if scanUpToCharactersFromSet(set, intoString: &value),
            let value = value as? String {
                return value
        }
        return nil
    }
    
    /// Returns an Int if scanned, or `nil` if not found.
    func scanInteger() -> Int? {
        var value = 0
        if scanInteger(&value) {
            return value
        }
        return nil
    }
    
}

