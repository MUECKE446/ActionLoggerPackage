//
//  ActionLogger.swift
//
//  Created by Christian Muth on 12.04.15.
//  Copyright (c) 2015 Christian Muth. All rights reserved.
//


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
// - The main logging class
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
        static let logQueueIdentifier = "de.muecke-software.ActionLogger.queue"
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
        static let ActionLoggerVersion: String = "1.0.0"
    }
    
    struct statics {
        static var loggerDict = [String: ActionLogger]()
        static let defaultLogger: ActionLogger! = ActionLogger(identifier:ActionLogger.constants.defaultLoggerIdentifier)
        static var logQueue = dispatch_queue_create(ActionLogger.constants.logQueueIdentifier, nil)
        static let standardLogConsoleDestination: ActionLogDestinationColorProtocol =  ActionLogConsoleDestination(identifier: ActionLogger.constants.baseConsoleDestinationIdentifier)
    }
    
    public var dateFormatter: NSDateFormatter
    
    // MARK: - Enums
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
    
    // MARK: - Properties (Options)
    public let identifier: String
    
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
    
    // MARK: - Properties
    
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
    public class func setup(logLevel: LogLevel = .AllLevels, showDateAndTime: Bool = true, showLogLevel: Bool = true, showFileName: Bool = true, showLineNumber: Bool = true, showFuncName: Bool = true, dateFormatter: NSDateFormatter = ActionLogger.dateFormatterGER, writeToFile: AnyObject? = nil) {
        defaultLogger().setup(logLevel, showDateAndTime: showDateAndTime, showLogLevel: showLogLevel, showFileName: showFileName, showLineNumber: showLineNumber, showFuncName: showFuncName, dateFormatter: dateFormatter, writeToFile: writeToFile)
    }
    
    public func setup(logLevel: LogLevel = .AllLevels, showDateAndTime: Bool = true,  showLogLevel: Bool = true, showFileName: Bool = true, showLineNumber: Bool = true, showFuncName: Bool = true, dateFormatter: NSDateFormatter = ActionLogger.dateFormatterGER, writeToFile: AnyObject? = nil) {
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
        
        for logDestination in logDestinations {
            if logDestination is ActionLogConsoleDestination {
                (logDestination as! ActionLogConsoleDestination).outputLogLevel = logLevel
                (logDestination as! ActionLogConsoleDestination).showDateAndTime = showDateAndTime
                (logDestination as! ActionLogConsoleDestination).showLogLevel = showLogLevel
                (logDestination as! ActionLogConsoleDestination).showFileName = showFileName
                (logDestination as! ActionLogConsoleDestination).showLineNumber = showLineNumber
                (logDestination as! ActionLogConsoleDestination).showFuncName = showFuncName
                (logDestination as! ActionLogConsoleDestination).dateFormatter = dateFormatter
                continue
            }
            if logDestination is ActionLogFileDestination {
                (logDestination as! ActionLogFileDestination).outputLogLevel = logLevel
                (logDestination as! ActionLogFileDestination).showDateAndTime = showDateAndTime
                (logDestination as! ActionLogFileDestination).showLogLevel = showLogLevel
                (logDestination as! ActionLogFileDestination).showFileName = showFileName
                (logDestination as! ActionLogFileDestination).showLineNumber = showLineNumber
                (logDestination as! ActionLogFileDestination).showFuncName = showFuncName
                (logDestination as! ActionLogFileDestination).dateFormatter = dateFormatter
                continue
            }
        }
    }
    
    public class func setupLogLevel(logLevel: ActionLogger.LogLevel) {
        defaultLogger().setupLogLevel(logLevel)
    }
    
    public func setupLogLevel(logLevel: ActionLogger.LogLevel) {
        outputLogLevel = logLevel;
        
        for logDestination in logDestinations {
            if logDestination is ActionLogConsoleDestination {
                (logDestination as! ActionLogConsoleDestination).outputLogLevel = logLevel
                continue
            }
            if logDestination is ActionLogFileDestination {
                (logDestination as! ActionLogFileDestination).outputLogLevel = logLevel
                continue
            }
        }
    }
    
    
    public class func setupShowDateAndTime(showDateAndTime: Bool) {
        defaultLogger().setupShowDateAndTime(showDateAndTime)
    }
    
    public func setupShowDateAndTime(showDateAndTime: Bool) {
        for logDestination in logDestinations {
            if logDestination is ActionLogConsoleDestination {
                (logDestination as! ActionLogConsoleDestination).showDateAndTime = showDateAndTime
                continue
            }
            if logDestination is ActionLogFileDestination {
                (logDestination as! ActionLogFileDestination).showDateAndTime = showDateAndTime
                continue
            }
        }
    }
    
    public class func setupShowLogLevel(showLogLevel: Bool) {
        defaultLogger().setupShowLogLevel(showLogLevel)
    }
    
    public func setupShowLogLevel(showLogLevel: Bool) {
        for logDestination in logDestinations {
            if logDestination is ActionLogConsoleDestination {
                (logDestination as! ActionLogConsoleDestination).showLogLevel = showLogLevel
                continue
            }
            if logDestination is ActionLogFileDestination {
                (logDestination as! ActionLogFileDestination).showLogLevel = showLogLevel
                continue
            }
        }
    }
    
    public class func setupShowFileName(showFileName: Bool) {
        defaultLogger().setupShowFileName(showFileName)
    }
    
    public func setupShowFileName(showFileName: Bool) {
        for logDestination in logDestinations {
            if logDestination is ActionLogConsoleDestination {
                (logDestination as! ActionLogConsoleDestination).showFileName = showFileName
                continue
            }
            if logDestination is ActionLogFileDestination {
                (logDestination as! ActionLogFileDestination).showFileName = showFileName
                continue
            }
        }
    }
    
    public class func setupShowLineNumber(showLineNumber: Bool) {
        defaultLogger().setupShowLineNumber(showLineNumber)
    }
    
    public func setupShowLineNumber(showLineNumber: Bool) {
        for logDestination in logDestinations {
            if logDestination is ActionLogConsoleDestination {
                (logDestination as! ActionLogConsoleDestination).showLineNumber = showLineNumber
                continue
            }
            if logDestination is ActionLogFileDestination {
                (logDestination as! ActionLogFileDestination).showLineNumber = showLineNumber
                continue
            }
        }
    }
    
    public class func setupShowFuncName(showFuncName: Bool) {
        defaultLogger().setupShowFuncName(showFuncName)
    }
    
    public func setupShowFuncName(showFuncName: Bool) {
        for logDestination in logDestinations {
            if logDestination is ActionLogConsoleDestination {
                (logDestination as! ActionLogConsoleDestination).showFuncName = showFuncName
                continue
            }
            if logDestination is ActionLogFileDestination {
                (logDestination as! ActionLogFileDestination).showFuncName = showFuncName
                continue
            }
        }
    }
    
    
    public class func setupDateFormatter(dateFormatter: NSDateFormatter) {
        defaultLogger().setupDateFormatter(dateFormatter)
    }
    
    public func setupDateFormatter(dateFormatter: NSDateFormatter) {
        for logDestination in logDestinations {
            if logDestination is ActionLogConsoleDestination {
                (logDestination as! ActionLogConsoleDestination).dateFormatter = dateFormatter
                continue
            }
            if logDestination is ActionLogFileDestination {
                (logDestination as! ActionLogFileDestination).dateFormatter = dateFormatter
                continue
            }
        }
    }
    
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


// color enhancement
// MARK: - ActionLogColorProfile
struct ActionLogColorProfile {
    
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

// color enhancement
// MARK: - ActionLogDestinationColorProtocol
// - Protocol for output classes to conform to
protocol ActionLogDestinationColorProtocol: ActionLogDestinationProtocol {
    func setLogColors(foregroundRed fg_red: UInt8, foregroundGreen fg_green: UInt8, foregroundBlue fg_blue: UInt8, backgroundRed bg_red: UInt8, backgroundGreen bg_green: UInt8, backgroundBlue bg_blue: UInt8, forLogLevel logLevel: ActionLogger.LogLevel)
    func resetAllLogColors()
    
}

// MARK: - ActionLogDestinationProtocol
// - Protocol for output classes to conform to
public protocol ActionLogDestinationProtocol: CustomDebugStringConvertible {
    var identifier: String {get set}
    var showDateAndTime: Bool {get set}
    var showLogLevel: Bool {get set}
    var showFileName: Bool {get set}
    var showLineNumber: Bool {get set}
    var showFuncName: Bool {get set}
    var dateFormatter: NSDateFormatter {get set}
    
    func processLogDetails(logDetails: ActionLogDetails, withFileLineFunctionInfo: Bool)
    func isEnabledForLogLevel(logLevel: ActionLogger.LogLevel) -> Bool
    func hasFile() -> Bool
    // color enhancement
    func isEnabledForColor() -> Bool
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

// MARK: - ActionLogConsoleDestination
/// - A standard log destination that outputs log details to the console
public class ActionLogConsoleDestination : ActionLogDestinationColorProtocol, CustomDebugStringConvertible {
    //    var owner: ActionLogger
    public var identifier: String
    
    public var showDateAndTime: Bool = true
    public var showLogLevel: Bool = true
    public var showFileName: Bool = true
    public var showLineNumber: Bool = true
    public var showFuncName: Bool = true
    public var dateFormatter = ActionLogger.dateFormatterGER

    var outputLogLevel: ActionLogger.LogLevel = .AllLevels
    
    // color enhancement
    var colorProfiles = Dictionary<ActionLogger.LogLevel,ActionLogColorProfile>()
    
    
    init(identifier: String = "") {
        //        self.owner = owner
        self.identifier = identifier
        
        // color enhancement
        if isEnabledForColor() {
            // setting default color values
            #if os(OSX)
                self.colorProfiles[.AllLevels]    = ActionLogColorProfile(foregroundColor: NSColor.whiteColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.MessageOnly]  = ActionLogColorProfile(foregroundColor: NSColor.lightGrayColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Comment]      = ActionLogColorProfile(foregroundColor: NSColor.grayColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Verbose]      = ActionLogColorProfile(foregroundColor: NSColor.darkGrayColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Info]         = ActionLogColorProfile(foregroundColor: NSColor.blueColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Debug]        = ActionLogColorProfile(foregroundColor: NSColor.greenColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Warning]      = ActionLogColorProfile(foregroundColor: NSColor.orangeColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Error]        = ActionLogColorProfile(foregroundColor: NSColor.redColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Severe]       = ActionLogColorProfile(foregroundColor: NSColor.magentaColor(),backgroundColor: NSColor.whiteColor())
            #endif

            #if os(iOS)
                self.colorProfiles[.AllLevels]    = ActionLogColorProfile(foregroundColor: UIColor.whiteColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.MessageOnly]  = ActionLogColorProfile(foregroundColor: UIColor.lightGrayColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Comment]      = ActionLogColorProfile(foregroundColor: UIColor.grayColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Verbose]      = ActionLogColorProfile(foregroundColor: UIColor.darkGrayColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Info]         = ActionLogColorProfile(foregroundColor: UIColor.blueColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Debug]        = ActionLogColorProfile(foregroundColor: UIColor.greenColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Warning]      = ActionLogColorProfile(foregroundColor: UIColor.orangeColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Error]        = ActionLogColorProfile(foregroundColor: UIColor.redColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Severe]       = ActionLogColorProfile(foregroundColor: UIColor.magentaColor(),backgroundColor: UIColor.whiteColor())
            #endif
        }
    }
    
    public func setDefaultLogLevelColors() {
        // color enhancement
        if isEnabledForColor() {
            // setting default color values
            #if os(OSX)
                self.colorProfiles[.AllLevels]    = ActionLogColorProfile(foregroundColor: NSColor.whiteColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.MessageOnly]  = ActionLogColorProfile(foregroundColor: NSColor.lightGrayColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Comment]      = ActionLogColorProfile(foregroundColor: NSColor.grayColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Verbose]      = ActionLogColorProfile(foregroundColor: NSColor.darkGrayColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Info]         = ActionLogColorProfile(foregroundColor: NSColor.blueColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Debug]        = ActionLogColorProfile(foregroundColor: NSColor.greenColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Warning]      = ActionLogColorProfile(foregroundColor: NSColor.orangeColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Error]        = ActionLogColorProfile(foregroundColor: NSColor.redColor(),backgroundColor: NSColor.whiteColor())
                self.colorProfiles[.Severe]       = ActionLogColorProfile(foregroundColor: NSColor.magentaColor(),backgroundColor: NSColor.whiteColor())
            #endif
            
            #if os(iOS)
                self.colorProfiles[.AllLevels]    = ActionLogColorProfile(foregroundColor: UIColor.whiteColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.MessageOnly]  = ActionLogColorProfile(foregroundColor: UIColor.lightGrayColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Comment]      = ActionLogColorProfile(foregroundColor: UIColor.grayColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Verbose]      = ActionLogColorProfile(foregroundColor: UIColor.darkGrayColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Info]         = ActionLogColorProfile(foregroundColor: UIColor.blueColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Debug]        = ActionLogColorProfile(foregroundColor: UIColor.greenColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Warning]      = ActionLogColorProfile(foregroundColor: UIColor.orangeColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Error]        = ActionLogColorProfile(foregroundColor: UIColor.redColor(),backgroundColor: UIColor.whiteColor())
                self.colorProfiles[.Severe]       = ActionLogColorProfile(foregroundColor: UIColor.magentaColor(),backgroundColor: UIColor.whiteColor())
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
            dispatch_sync(ActionLogger.statics.logQueue) {
                print(fullLogMessage, terminator: "")
            }
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
    // MARK: - ActionLogDestinationColorProtocol
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
    
    var outputLogLevel: ActionLogger.LogLevel = .AllLevels
    
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




