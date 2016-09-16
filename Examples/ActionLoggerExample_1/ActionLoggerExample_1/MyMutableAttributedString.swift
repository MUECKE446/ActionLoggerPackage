//
//  MyMutableAttributedString.swift
//  ActionLoggerExample_1
//
//  Created by Christian Muth on 02.01.16.
//  Copyright © 2016 Christian Muth. All rights reserved.
//

import Cocoa


class MyMutableAttributedString: NSMutableAttributedString {
    
    fileprivate var _contents: NSMutableAttributedString
    
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
    

    required init?(pasteboardPropertyList propertyList: Any, ofType type: String) {
        fatalError("init(pasteboardPropertyList:ofType:) has not been implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [String : Any] {
        return (self._contents.attributes(at: location, effectiveRange: range))
    }
    
    override func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        self._contents.replaceCharacters(in: range, with: attrString)
    }
    
    override func setAttributes(_ attrs: [String : Any]?, range: NSRange) {
        self._contents.setAttributes(attrs, range: range)
    }
    
    override func fixAttachmentAttribute(in range: NSRange) {
        self._contents.fixAttributes(in: range)
        XcodeColors()
    }

    
    fileprivate func XcodeColors() {
        _ = string as NSString
        let editedRange = NSRange.init(location: 0, length: self._contents.length)
        
        //var attrs = NSMutableDictionary(capacity: 2)
        let attrs = NSMutableDictionary(objects: [NSColor.clear,NSColor.clear], forKeys: [NSBackgroundColorAttributeName as NSCopying,NSForegroundColorAttributeName as NSCopying])
        attrs.removeObject(forKey: NSForegroundColorAttributeName)
        attrs.removeObject(forKey: NSBackgroundColorAttributeName)

        // Attribute fürs unsichtbar machen
        let clearAttrs = NSDictionary(objects: [NSFont.systemFont(ofSize: 0.001),NSColor.clear], forKeys: [NSFontAttributeName as NSCopying,NSForegroundColorAttributeName as NSCopying])

        // finde alle ESCAPEs
        let matchesEscapeSequencesPattern = escapeSequencePattern.matches(in: string, options: .reportProgress, range: editedRange)
        
        setColorsInComponents(matchesEscapeSequencesPattern, colorAttributes: attrs, string: string)
        
        // finde zunächst alle Sequenzen für die Vordergrund Farbe
        let matchesColorPrefixForegroundPattern = xcodeColorPrefixForegroundPattern.matches(in: string, options: .reportProgress, range: editedRange)
        for result in matchesColorPrefixForegroundPattern {
            // der Bereich dieser Sequenz wird unsichtbar gemacht
            self.addAttributes(clearAttrs as! [String : AnyObject], range: result.range)
        }
        
        // finde zunächst alle Sequenzen für die Hintergrundfarbe
        let matchesColorPrefixBackgroundPattern = xcodeColorPrefixBackgroundPattern.matches(in: string, options: .reportProgress, range: editedRange)
        for result in matchesColorPrefixBackgroundPattern {
            // der Bereich dieser Sequenz wird unsichtbar gemacht
            self.addAttributes(clearAttrs as! [String : AnyObject], range: result.range)
        }
        
        let matchesResetForegroundPattern = xcodeColorResetForegroundPattern.matches(in: string, options: .reportProgress, range: editedRange)
        for result in matchesResetForegroundPattern {
            // der Bereich dieser Sequenz wird unsichtbar gemacht
            self.addAttributes(clearAttrs as! [String : AnyObject], range: result.range)

        }

        let matchesResetBackgroundPattern = xcodeColorResetBackgroundPattern.matches(in: string, options: .reportProgress, range: editedRange)
        for result in matchesResetBackgroundPattern {
            // der Bereich dieser Sequenz wird unsichtbar gemacht
            self.addAttributes(clearAttrs as! [String : AnyObject], range: result.range)

        }

        let matchesResetForeAndBackgroundPattern = xcodeColorResetForeAndBackgroundPattern.matches(in: string, options: .reportProgress, range: editedRange)
        for result in matchesResetForeAndBackgroundPattern {
            // der Bereich dieser Sequenz wird unsichtbar gemacht
            self.addAttributes(clearAttrs as! [String : AnyObject], range: result.range)
        }
        // hier müßte ich alle Esc Sequenzen zusammenhaben
    }
    
    func setColorsInComponents(_ xs: [NSTextCheckingResult], colorAttributes: NSMutableDictionary, string: String) {
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
            let tmpStr = text.substring(with: r) as NSString
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
                    colorAttributes.removeObject(forKey: NSForegroundColorAttributeName)
                    colorAttributes.removeObject(forKey: NSBackgroundColorAttributeName)
                }
                else {
                    if reset_fg {
                        colorAttributes.removeObject(forKey: NSForegroundColorAttributeName)
                    }
                    else {
                        colorAttributes.removeObject(forKey: NSBackgroundColorAttributeName)
                    }
                }
            }
            else {
                // nun kann es sich nur noch um einen neuen Wert für Vorder- oder Hintergrungfarbe handeln
                
                // finde Sequenz für die Vordergrundfarbe
                let matchesColorPrefixForegroundPattern = xcodeColorPrefixForegroundPattern.matches(in: tmpStr as String, options: .reportProgress, range: NSRange.init(location: 0, length: tmpStr.length))
                // finde Sequenz für die Hintergrundfarbe
                let matchesColorPrefixBackgroundPattern = xcodeColorPrefixBackgroundPattern.matches(in: tmpStr as String, options: .reportProgress, range: NSRange.init(location: 0, length: tmpStr.length))
                
                if !matchesColorPrefixForegroundPattern.isEmpty {
                    // das ist die Sequenz: \\x1b\\[fg[0-9][0-9]{0,2},[0-9][0-9]{0,2},[0-9][0-9]{0,2};
                    let string1 = tmpStr.substring(with: matchesColorPrefixForegroundPattern[0].range)
                    colorAttributes.setObject(getColor(components: string1), forKey: NSForegroundColorAttributeName as NSCopying)
                }
                else {
                    assert(!matchesColorPrefixBackgroundPattern.isEmpty)
                    // das ist die Sequenz: \\x1b\\[bg[0-9][0-9]{0,2},[0-9][0-9]{0,2},[0-9][0-9]{0,2};
                    let string1 = tmpStr.substring(with: matchesColorPrefixBackgroundPattern[0].range)
                    colorAttributes.setObject(getColor(components: string1), forKey: NSBackgroundColorAttributeName as NSCopying)
                }
            }
            // nun kann die Komponente mit den Farben versehen werden
            self.addAttributes(colorAttributes as NSDictionary as! [String : AnyObject], range: r)
        }
    }
    
    fileprivate func getColor(components componentString: String) -> NSColor {
        let searchString = componentString.substring(from: componentString.characters.index(componentString.characters.startIndex, offsetBy: 4))
        let text1 = searchString as NSString
        let matchesColorsPattern = xcodeColorsPattern.matches(in: searchString, options: .reportProgress, range: NSMakeRange(0, searchString.characters.count))
        // es müssen 3 Farbkomponenten gefunden werden
        assert(matchesColorsPattern.count == 3)
        let str_r = text1.substring(with: matchesColorsPattern[0].range)
        let str_g = text1.substring(with: matchesColorsPattern[1].range)
        let str_b = text1.substring(with: matchesColorsPattern[2].range)
        // wandle die Strings in Ints
        let r = CGFloat.init(Int(str_r)!)
        let g = CGFloat.init(Int(str_g)!)
        let b = CGFloat.init(Int(str_b)!)
        
        let color = NSColor(calibratedRed: (r/255.0), green: (g/255.0), blue: (b/255.0), alpha: 1.0)
        return color
        
    }
    
    fileprivate var pattern: NSRegularExpression {
        // The second capture is either a file extension (default) or a function name (SwiftyBeaver format).
        // Callers should check for the presence of the third capture to detect if it is SwiftyBeaver or not.
        //
        // (If this gets any more complicated there will need to be a formal way to walk through multiple
        // patterns and check if each one matches.)
        return try! NSRegularExpression(pattern: "([\\w\\+]+)\\.(\\w+)(\\(\\))?:(\\d+)", options: .caseInsensitive)
    }
    
    
    fileprivate var escapeSequencePattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "\\x1b\\[", options: .caseInsensitive)
    }
    
    
    fileprivate var xcodeColorPrefixPattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "\\x1b\\[fg[0-9][0-9]{0,2},[0-9][0-9]{0,2},[0-9][0-9]{0,2};\\x1b\\[bg[0-9][0-9]{0,2},[0-9][0-9]{0,2},[0-9][0-9]{0,2};", options: .caseInsensitive)
    }
    
    fileprivate var xcodeColorPrefixForegroundPattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "\\x1b\\[fg[0-9][0-9]{0,2},[0-9][0-9]{0,2},[0-9][0-9]{0,2};", options: .caseInsensitive)
    }
    
    fileprivate var xcodeColorPrefixBackgroundPattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "\\x1b\\[bg[0-9][0-9]{0,2},[0-9][0-9]{0,2},[0-9][0-9]{0,2};", options: .caseInsensitive)
    }
    
    fileprivate var xcodeColorsPattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "([0-9][0-9]{0,2})", options: .caseInsensitive)
    }
    
    
    
    fileprivate var xcodeColorResetForegroundPattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "\\x1b\\[fg;", options: .caseInsensitive)
    }
    
    fileprivate var xcodeColorResetBackgroundPattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "\\x1b\\[bg;", options: .caseInsensitive)
    }
    
    fileprivate var xcodeColorResetForeAndBackgroundPattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "\\x1b\\[;", options: .caseInsensitive)
    }

    
}
