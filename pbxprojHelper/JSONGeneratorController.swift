//
//  JSONGeneratorController.swift
//  pbxprojHelper
//
//  Created by 杨萧玉 on 2016/9/28.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

import Cocoa

class JSONGeneratorController: NSViewController {

    @IBOutlet weak var latestProjectFilePathTF: NSTextField!
    @IBOutlet weak var originalProjectFilePathTF: NSTextField!
    @IBOutlet weak var jsonFileSavePathTF: NSTextField!
    
    var modifiedProjectURL: URL?
    var originalProjectURL: URL?
    
    let openPanel = NSOpenPanel()
    
    @IBAction func openLatestProject(_ sender: NSButton) {
        openPanel.prompt = "Select"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["pbxproj", "xcodeproj"]
        if openPanel.runModal().rawValue == NSFileHandlingPanelOKButton {
            if let url = openPanel.url {
                latestProjectFilePathTF.stringValue = url.path
                modifiedProjectURL = url
            }
        }

    }
    
    @IBAction func openOriginalProject(_ sender: NSButton) {
        openPanel.prompt = "Select"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["pbxproj", "xcodeproj"]
        if openPanel.runModal().rawValue == NSFileHandlingPanelOKButton {
            if let url = openPanel.url {
                originalProjectFilePathTF.stringValue = url.path
                originalProjectURL = url
            }
        }
    }
    
    @IBAction func chooseJSONSavePath(_ sender: NSButton) {
        openPanel.prompt = "Select"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        if openPanel.runModal().rawValue == NSFileHandlingPanelOKButton {
            if let url = openPanel.url {
                jsonFileSavePathTF.stringValue = url.path
            }
        }
    }
    
    @IBAction func generateJSONFile(_ sender: NSButton) {
        guard modifiedProjectURL == nil || originalProjectURL == nil else {
            sender.title = "Generating"
            DispatchQueue.global().async {
                PropertyListHandler.generateJSON(filePath: self.jsonFileSavePathTF.stringValue, withModifiedProject: self.modifiedProjectURL!, originalProject: self.originalProjectURL!)
                DispatchQueue.main.async {
                    sender.title = "Generate"
                }
            }
            return
        }
    }
}
