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
    let recentUsePathsKey = "recentUsePaths"
    let projectConfigurationPathPairsKey = "projectConfigurationPathPair"

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        initWindow = NSApplication.shared.windows.first
        loadBookmarks()
        
        let pathsData = NSKeyedArchiver.archivedData(withRootObject: recentUsePaths)
        let projectConfigurationPathPairsData = NSKeyedArchiver.archivedData(withRootObject: projectConfigurationPathPairs)
        
        userDefaults.register(defaults: [recentUsePathsKey : pathsData])
        userDefaults.register(defaults: [projectConfigurationPathPairsKey : projectConfigurationPathPairsData])
        
        if let pathsData = userDefaults.object(forKey: recentUsePathsKey) as? Data,
            let unarchivePathsData = NSKeyedUnarchiver.unarchiveObject(with: pathsData) as? LRUCache <String, String>,
        let pairsData = userDefaults.object(forKey: projectConfigurationPathPairsKey) as? Data,
        let unarchivePairsData = NSKeyedUnarchiver.unarchiveObject(with: pairsData) as? [String : URL] {
            recentUsePaths = unarchivePathsData
            projectConfigurationPathPairs = unarchivePairsData
            if recentUsePaths.count > 0 {
                let path = recentUsePaths[0]
                if let viewController = initWindow?.contentViewController as? ViewController {
                    viewController.handleSelectProjectFileURL(URL(fileURLWithPath: path))
                    if let projectPath = viewController.propertyListURL?.path,
                        let jsonURL = projectConfigurationPathPairs[projectPath] {
                        viewController.handleSelectJSONFileURL(jsonURL)
                    }
                }
            }
        }
        recentUsePaths.countLimit = 5
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        
        let pathsData = NSKeyedArchiver.archivedData(withRootObject: recentUsePaths)
        userDefaults.set(pathsData, forKey: recentUsePathsKey)
        let pairsData = NSKeyedArchiver.archivedData(withRootObject: projectConfigurationPathPairs)
        userDefaults.set(pairsData, forKey: projectConfigurationPathPairsKey)
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

