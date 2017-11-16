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
        openPanel.begin { (result) in
            if NSApplication.ModalResponse.OK == result, let url = self.openPanel.url {
                self.latestProjectFilePathTF.stringValue = url.path
                self.modifiedProjectURL = url
            }
        }
    }
    
    @IBAction func openOriginalProject(_ sender: NSButton) {
        openPanel.prompt = "Select"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["pbxproj", "xcodeproj"]
        openPanel.begin { (result) in
            if NSApplication.ModalResponse.OK == result, let url = self.openPanel.url {
                self.originalProjectFilePathTF.stringValue = url.path
                self.originalProjectURL = url
            }
        }
    }
    
    @IBAction func chooseJSONSavePath(_ sender: NSButton) {
        openPanel.prompt = "Select"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true
        openPanel.begin { (result) in
            if NSApplication.ModalResponse.OK == result, let url = self.openPanel.url {
                self.jsonFileSavePathTF.stringValue = url.path
            }
        }
    }
    
    @IBAction func generateJSONFile(_ sender: NSButton) {
        let filePath = self.jsonFileSavePathTF.stringValue
        guard modifiedProjectURL == nil || originalProjectURL == nil || filePath.count == 0 else {
            sender.title = "Generating"
            DispatchQueue.global().async {
                PropertyListHandler.generateJSON(filePath: filePath, withModifiedProject: self.modifiedProjectURL!, originalProject: self.originalProjectURL!)
                DispatchQueue.main.async {
                    sender.title = "Generate"
                }
            }
            return
        }
    }
}
