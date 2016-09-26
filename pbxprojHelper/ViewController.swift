//
//  ViewController.swift
//  pbxprojHelper
//
//  Created by 杨萧玉 on 2016/9/24.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

import Cocoa

typealias Item = (key: String, value: Any, parent: Any?)

class ViewController: NSViewController {

    @IBOutlet weak var filePathTF: NSTextField!
    @IBOutlet weak var resultTable: NSOutlineView!
    @IBOutlet weak var selectBtn: NSButton!
    
    var propertyListURL: URL?
    
    var originalPropertyList: [String: Any] = [:]
    var currentProperyList: [String: Any] = [:]
    var filterPropertyList: [String: Any] = [:]
    var jsonPropertyList: [String: Any] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func search(key:String, inItem item:Any?) -> Any? {
        for i in 0 ..< resultTable.numberOfChildren(ofItem: item) {
            if let child = resultTable.child(i, ofItem: item) as? Item {
                if child.key == key {
                    return child
                }
                else if let result = search(key: key, inItem: child) as? Item, result.key == key {
                    return result
                }
            }
        }
        return nil
    }
    
    func keyPath(forItem item: Any) -> String {
        let key: String
        let parent: Any?
        if let tupleItem = item as? Item {
            key = tupleItem.key
            parent = tupleItem.parent
        }
        else {
            key = ""
            parent = nil
        }
        
        if let parentItem = parent {
            return "\(keyPath(forItem: parentItem)).\(key)"
        }
        return "\(key)"
    }
    
    func writePasteboard(_ location: String) {
        NSPasteboard.general().declareTypes([NSStringPboardType], owner: nil)
        NSPasteboard.general().setString(location, forType: NSStringPboardType)
    }
    
}

//MARK: - User Action

extension ViewController {
    
    @IBAction func selectFile(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Select"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["pbxproj", "xcodeproj"]
        
        if openPanel.runModal() == NSFileHandlingPanelOKButton {
            if let url = openPanel.url {
                filePathTF.stringValue = url.path
                propertyListURL = url
                if let data = PropertyListHandler.parseProject(fileURL: url) {
                    originalPropertyList = data;
                    currentProperyList = data;
                    jsonPropertyList = data;
                    filterPropertyList = data;
                    resultTable.reloadData()
                }
            }
        }
    }
    
    @IBAction func chooseJSONFile(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Select"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        if openPanel.runModal() == NSFileHandlingPanelOKButton {
            if let url = openPanel.url,
            let data = PropertyListHandler.parseJSONFileURL(url) as? [String: [String: Any]] {
                PropertyListHandler.apply(json: data, onProjectData: &jsonPropertyList)
                currentProperyList = jsonPropertyList
                resultTable.reloadData()
            }
        }
    }
    
    @IBAction func applyJSONConfiguration(_ sender: NSButton) {
        if let url = propertyListURL {
            PropertyListHandler.generateProject(fileURL: url, withPropertyList: jsonPropertyList)
        }
    }
    
    @IBAction func click(_ sender: NSOutlineView) {
        let item = sender.item(atRow: sender.clickedRow)
        let column = sender.tableColumns[sender.clickedColumn]
        if let selectedString = self.outlineView(sender, objectValueFor: column, byItem: item) as? String {
            writePasteboard(selectedString)
        }
    }
    
    @IBAction func doubleClick(_ sender: NSOutlineView) {
        let item = sender.item(atRow: sender.clickedRow)
        let path = keyPath(forItem: item)
        writePasteboard(path)
    }
}

//MARK: - NSOutlineViewDataSource
extension ViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return currentProperyList.count
        }
        let itemValue = (item as? Item)?.value
        if let dictionary = itemValue as? [String: Any] {
            return dictionary.count
        }
        if let array = itemValue as? [Any] {
            return array.count
        }
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return self.outlineView(outlineView, numberOfChildrenOfItem: item) > 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let itemValue = (item as? Item)?.value
        if let dictionary = item == nil ? currentProperyList : (itemValue as? [String: Any]) {
            let keys = Array(dictionary.keys)
            let key = keys[index]
            let value = dictionary[key] ?? ""
            return Item(key: key, value: value, parent: item)
        }
        if let array = (itemValue as? [String]) {
            return Item(key: array[index], value: "", parent: item)
        }
        return Item(key: "", value: "", parent: item)
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        if let pair = item as? Item {
            if tableColumn?.identifier == "Key" {
                return pair.key
            }
            if tableColumn?.identifier == "Value" {
                if let value = pair.value as? [String: Any] {
                    return "Dictionary (\(value.count) elements)"
                }
                if let value = pair.value as? [Any] {
                    return "Array (\(value.count) elements)"
                }
                return pair.value
            }
        }
        return nil
    }
}

//MARK: - NSOutlineViewDelegate

extension ViewController: NSOutlineViewDelegate {
    
    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
        return false
    }
}

//MARK: - NSTextFieldDelegate
extension ViewController: NSTextFieldDelegate {
    
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        
        return true
    }
}
