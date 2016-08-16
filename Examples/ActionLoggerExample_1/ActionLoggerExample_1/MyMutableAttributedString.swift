//
//  MyMutableAttributedString.swift
//  ActionLoggerExample_1
//
//  Created by Christian Muth on 02.01.16.
//  Copyright © 2016 Christian Muth. All rights reserved.
//

import Cocoa


class MyMutableAttributedString: NSMutableAttributedString {
    
    private var _contents: NSMutableAttributedString
    
    override var string: String {
        get {
            return self._contents.string
        }
    }
    
    override init() {
        self._contents = NSMutableAttributedString()
        super.init()
    }

    override init(attributedString attrStr: NSAttributedString?) {
        if let _ = attrStr {
            self._contents = (attrStr!.mutableCopy() as! NSMutableAttributedString)
        }
        else {
            self._contents = NSMutableAttributedString()
        }
        super.init()
    }
    
    override init(string str: String) {
        self._contents = NSMutableAttributedString.init(string: str)
        super.init()
    }
    

    required init?(pasteboardPropertyList propertyList: AnyObject, ofType type: String) {
        fatalError("init(pasteboardPropertyList:ofType:) has not been implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func attributesAtIndex(location: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] {
        return (self._contents.attributesAtIndex(location, effectiveRange: range))
    }
    
    override func replaceCharactersInRange(range: NSRange, withAttributedString attrString: NSAttributedString) {
        self._contents.replaceCharactersInRange(range, withAttributedString: attrString)
    }
    
    override func setAttributes(attrs: [String : AnyObject]?, range: NSRange) {
        self._contents.setAttributes(attrs, range: range)
    }
    
    override func fixAttachmentAttributeInRange(range: NSRange) {
        self._contents.fixAttributesInRange(range)
        XcodeColors()
    }

    
    private func XcodeColors() {
        _ = string as NSString
        let editedRange = NSRange.init(location: 0, length: self._contents.length)
        
        //var attrs = NSMutableDictionary(capacity: 2)
        let attrs = NSMutableDictionary(objects: [NSColor.clearColor(),NSColor.clearColor()], forKeys: [NSBackgroundColorAttributeName,NSForegroundColorAttributeName])
        attrs.removeObjectForKey(NSForegroundColorAttributeName)
        attrs.removeObjectForKey(NSBackgroundColorAttributeName)

        // Attribute fürs unsichtbar machen
        let clearAttrs = NSDictionary(objects: [NSFont.systemFontOfSize(0.001),NSColor.clearColor()], forKeys: [NSFontAttributeName,NSForegroundColorAttributeName])

        // finde alle ESCAPEs
        let matchesEscapeSequencesPattern = escapeSequencePattern.matchesInString(string, options: .ReportProgress, range: editedRange)
        
        setColorsInComponents(matchesEscapeSequencesPattern, colorAttributes: attrs, string: string)
        
        // finde zunächst alle Sequenzen für die Vordergrund Farbe
        let matchesColorPrefixForegroundPattern = xcodeColorPrefixForegroundPattern.matchesInString(string, options: .ReportProgress, range: editedRange)
        for result in matchesColorPrefixForegroundPattern {
            // der Bereich dieser Sequenz wird unsichtbar gemacht
            self.addAttributes(clearAttrs as! [String : AnyObject], range: result.range)
        }
        
        // finde zunächst alle Sequenzen für die Hintergrundfarbe
        let matchesColorPrefixBackgroundPattern = xcodeColorPrefixBackgroundPattern.matchesInString(string, options: .ReportProgress, range: editedRange)
        for result in matchesColorPrefixBackgroundPattern {
            // der Bereich dieser Sequenz wird unsichtbar gemacht
            self.addAttributes(clearAttrs as! [String : AnyObject], range: result.range)
        }
        
        let matchesResetForegroundPattern = xcodeColorResetForegroundPattern.matchesInString(string, options: .ReportProgress, range: editedRange)
        for result in matchesResetForegroundPattern {
            // der Bereich dieser Sequenz wird unsichtbar gemacht
            self.addAttributes(clearAttrs as! [String : AnyObject], range: result.range)

        }

        let matchesResetBackgroundPattern = xcodeColorResetBackgroundPattern.matchesInString(string, options: .ReportProgress, range: editedRange)
        for result in matchesResetBackgroundPattern {
            // der Bereich dieser Sequenz wird unsichtbar gemacht
            self.addAttributes(clearAttrs as! [String : AnyObject], range: result.range)

        }

        let matchesResetForeAndBackgroundPattern = xcodeColorResetForeAndBackgroundPattern.matchesInString(string, options: .ReportProgress, range: editedRange)
        for result in matchesResetForeAndBackgroundPattern {
            // der Bereich dieser Sequenz wird unsichtbar gemacht
            self.addAttributes(clearAttrs as! [String : AnyObject], range: result.range)
        }
        // hier müßte ich alle Esc Sequenzen zusammenhaben
    }
    
    func setColorsInComponents(xs: [NSTextCheckingResult], colorAttributes: NSMutableDictionary, string: String) {
        var resultArr: [NSRange] = []
        let text = string as NSString
        let length = text.length
        
        for i in 0 ... xs.count-1 {
            let range_n_1 = xs[i].range
            if i < xs.count-1 {
                let range_n = xs[i+1].range
                let result = NSRange.init(location: range_n_1.location, length: range_n.location - range_n_1.location)
                resultArr.append(result)
            }
            else {
                let result = NSRange.init(location: range_n_1.location, length: length - range_n_1.location)
                resultArr.append(result)
            }
        }
        // nun ist der gesamte string in components aufgeteilt
        // stelle nun fest, um was es sich im einzelnen handelt
        for r in resultArr {
            let tmpStr = text.substringWithRange(r) as NSString
            var reset = false
            var reset_fg = false
            var reset_bg = false
            
            switch tmpStr.length {
            case 3:
                reset = tmpStr == "\u{1b}[;"
            case 5:
                reset_fg = tmpStr == "\u{1b}[fg;"
                reset_bg = tmpStr == "\u{1b}[bg;"
            default:
                 break
            }

            if reset || reset_fg || reset_bg {
                if reset {
                    // beide Attribute werden gelöscht
                    colorAttributes.removeObjectForKey(NSForegroundColorAttributeName)
                    colorAttributes.removeObjectForKey(NSBackgroundColorAttributeName)
                }
                else {
                    if reset_fg {
                        colorAttributes.removeObjectForKey(NSForegroundColorAttributeName)
                    }
                    else {
                        colorAttributes.removeObjectForKey(NSBackgroundColorAttributeName)
                    }
                }
            }
            else {
                // nun kann es sich nur noch um einen neuen Wert für Vorder- oder Hintergrungfarbe handeln
                
                // finde Sequenz für die Vordergrundfarbe
                let matchesColorPrefixForegroundPattern = xcodeColorPrefixForegroundPattern.matchesInString(tmpStr as String, options: .ReportProgress, range: NSRange.init(location: 0, length: tmpStr.length))
                // finde Sequenz für die Hintergrundfarbe
                let matchesColorPrefixBackgroundPattern = xcodeColorPrefixBackgroundPattern.matchesInString(tmpStr as String, options: .ReportProgress, range: NSRange.init(location: 0, length: tmpStr.length))
                
                if !matchesColorPrefixForegroundPattern.isEmpty {
                    // das ist die Sequenz: \\x1b\\[fg[0-9][0-9]{0,2},[0-9][0-9]{0,2},[0-9][0-9]{0,2};
                    let string1 = tmpStr.substringWithRange(matchesColorPrefixForegroundPattern[0].range)
                    colorAttributes.setObject(getColor(components: string1), forKey: NSForegroundColorAttributeName)
                }
                else {
                    assert(!matchesColorPrefixBackgroundPattern.isEmpty)
                    // das ist die Sequenz: \\x1b\\[bg[0-9][0-9]{0,2},[0-9][0-9]{0,2},[0-9][0-9]{0,2};
                    let string1 = tmpStr.substringWithRange(matchesColorPrefixBackgroundPattern[0].range)
                    colorAttributes.setObject(getColor(components: string1), forKey: NSBackgroundColorAttributeName)
                }
            }
            // nun kann die Komponente mit den Farben versehen werden
            self.addAttributes(colorAttributes as NSDictionary as! [String : AnyObject], range: r)
        }
    }
    
    private func getColor(components componentString: String) -> NSColor {
        let searchString = componentString.substringFromIndex(componentString.characters.startIndex.advancedBy(4))
        let text1 = searchString as NSString
        let matchesColorsPattern = xcodeColorsPattern.matchesInString(searchString, options: .ReportProgress, range: NSMakeRange(0, searchString.characters.count))
        // es müssen 3 Farbkomponenten gefunden werden
        assert(matchesColorsPattern.count == 3)
        let str_r = text1.substringWithRange(matchesColorsPattern[0].range)
        let str_g = text1.substringWithRange(matchesColorsPattern[1].range)
        let str_b = text1.substringWithRange(matchesColorsPattern[2].range)
        // wandle die Strings in Ints
        let r = CGFloat.init(Int(str_r)!)
        let g = CGFloat.init(Int(str_g)!)
        let b = CGFloat.init(Int(str_b)!)
        
        let color = NSColor(calibratedRed: (r/255.0), green: (g/255.0), blue: (b/255.0), alpha: 1.0)
        return color
        
    }
    
    private var pattern: NSRegularExpression {
        // The second capture is either a file extension (default) or a function name (SwiftyBeaver format).
        // Callers should check for the presence of the third capture to detect if it is SwiftyBeaver or not.
        //
        // (If this gets any more complicated there will need to be a formal way to walk through multiple
        // patterns and check if each one matches.)
        return try! NSRegularExpression(pattern: "([\\w\\+]+)\\.(\\w+)(\\(\\))?:(\\d+)", options: .CaseInsensitive)
    }
    
    
    private var escapeSequencePattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "\\x1b\\[", options: .CaseInsensitive)
    }
    
    
    private var xcodeColorPrefixPattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "\\x1b\\[fg[0-9][0-9]{0,2},[0-9][0-9]{0,2},[0-9][0-9]{0,2};\\x1b\\[bg[0-9][0-9]{0,2},[0-9][0-9]{0,2},[0-9][0-9]{0,2};", options: .CaseInsensitive)
    }
    
    private var xcodeColorPrefixForegroundPattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "\\x1b\\[fg[0-9][0-9]{0,2},[0-9][0-9]{0,2},[0-9][0-9]{0,2};", options: .CaseInsensitive)
    }
    
    private var xcodeColorPrefixBackgroundPattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "\\x1b\\[bg[0-9][0-9]{0,2},[0-9][0-9]{0,2},[0-9][0-9]{0,2};", options: .CaseInsensitive)
    }
    
    private var xcodeColorsPattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "([0-9][0-9]{0,2})", options: .CaseInsensitive)
    }
    
    
    
    private var xcodeColorResetForegroundPattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "\\x1b\\[fg;", options: .CaseInsensitive)
    }
    
    private var xcodeColorResetBackgroundPattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "\\x1b\\[bg;", options: .CaseInsensitive)
    }
    
    private var xcodeColorResetForeAndBackgroundPattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "\\x1b\\[;", options: .CaseInsensitive)
    }

    
}
