//
//  AppDelegate.swift
//  FFTranscode
//
//  Created by Kartik Venugopal on 02/10/22.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!
    var transcoder: FFmpegTranscoder!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Note to Oli - Modify this path for your app run.
        let inFile = URL(fileURLWithPath: "/Volumes/Shared/Music/Bourne.wav")
        
        let inFileName = inFile.deletingPathExtension().lastPathComponent
        let outFile = inFile.parentDir.appendingPathComponent(inFileName + ".opus")
        
        transcodeSlightlyShort(inFile.path, outFile.path)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
