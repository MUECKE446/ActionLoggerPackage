# ActionLoggerPackage
All you need for logging

####Overview:

The Action Logger class sends messages to the Xcode console and / or a file (log). The messages are processed accordingly before they are issued. 
If the Xcode Plugin XcodeColors is installed, the messages in the Xcode console are displayed in color. 
The aim of the development was to implement a very easy-to-use method that can be generated with the reports to track program run during software testing. On the other hand has been achieved that through a variety of options, the class can also be used for any other protocol tasks.

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



