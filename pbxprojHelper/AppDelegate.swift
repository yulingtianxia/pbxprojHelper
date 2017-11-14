//
//  AppDelegate.swift
//  pbxprojHelper
//
//  Created by 杨萧玉 on 2016/9/24.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    weak var initWindow: NSWindow?
    let userDefaults = UserDefaults.standard

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        initWindow = NSApplication.shared.windows.first
        loadBookmarks()
        recentUsePaths = LRUCache <String, String>()
        let pathsData = NSKeyedArchiver.archivedData(withRootObject: recentUsePaths)
        
        userDefaults.register(defaults: ["recentUsePaths":pathsData])
        
        if let data = userDefaults.object(forKey: "recentUsePaths") as? Data,
            let unarchiveData = NSKeyedUnarchiver.unarchiveObject(with: data) as? LRUCache <String, String> {
            recentUsePaths = unarchiveData
        }
        recentUsePaths.countLimit = 5
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        let pathsData = NSKeyedArchiver.archivedData(withRootObject: recentUsePaths)
        userDefaults.set(pathsData, forKey: "recentUsePaths")
        saveBookmarks()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            return false
        }
        else {
            initWindow?.makeKeyAndOrderFront(self)
            return true
        }
    }
}

