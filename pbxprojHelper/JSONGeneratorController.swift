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
    
    var latestProjectURL: URL?
    var originalProjectURL: URL?
    
    let openPanel = NSOpenPanel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func openLatestProject(_ sender: NSButton) {
        openPanel.prompt = "Select"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["pbxproj", "xcodeproj"]
        if openPanel.runModal() == NSFileHandlingPanelOKButton {
            if let url = openPanel.url {
                latestProjectFilePathTF.stringValue = url.path
                latestProjectURL = url
            }
        }

    }
    
    @IBAction func openOriginalProject(_ sender: NSButton) {
        openPanel.prompt = "Select"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["pbxproj", "xcodeproj"]
        if openPanel.runModal() == NSFileHandlingPanelOKButton {
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
        if openPanel.runModal() == NSFileHandlingPanelOKButton {
            if let url = openPanel.url {
                jsonFileSavePathTF.stringValue = url.path
            }
        }
    }
    
    @IBAction func generateJSONFile(_ sender: NSButton) {
        guard latestProjectURL == nil || originalProjectURL == nil else {
            DispatchQueue.global().async {
                if let latestPropertyList = PropertyListHandler.parseProject(fileURL: self.latestProjectURL!),
                    let originalPropertyList = PropertyListHandler.parseProject(fileURL: self.originalProjectURL!) {
                    let jsonObject = PropertyListHandler.compare(project: latestPropertyList, withOtherProject: originalPropertyList)
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                        try jsonData.write(to: URL(fileURLWithPath: self.jsonFileSavePathTF.stringValue).appendingPathComponent("JsonConfiguration.json"), options: .atomic)
                    } catch let error {
                        print("generate json file error: \(error.localizedDescription)")
                    }
                }
            }
            return
        }
    }
}
