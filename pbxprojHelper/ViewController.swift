//
//  ViewController.swift
//  pbxprojHelper
//
//  Created by 杨萧玉 on 2016/9/24.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var filePathTF: NSTextField!
    @IBOutlet weak var resultTable: NSOutlineView!
    @IBOutlet weak var selectBtn: NSButton!
    var propertyList : [String: Any] = [:]
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    @IBAction func selectFile(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Select"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["pbxproj", "xcodeproj"]
        
        if openPanel.runModal() == NSFileHandlingPanelOKButton {
            if let path = openPanel.url?.path {
                filePathTF.stringValue = path
                if let data = PropertyListHandler.parseFilePath(path) {
                    propertyList = data;
                    resultTable.reloadData()
                }
            }
        }
    }
    
    func searchKey(_ key:String, inItem item:Any?) -> Any? {
        for i in 0 ..< resultTable.numberOfChildren(ofItem: item) {
            if let child = resultTable.child(i, ofItem: item) as? (String, Any) {
                if child.0 == key {
                    return child
                }
                else if let result = searchKey(key, inItem: child) as? (String, Any), result.0 == key {
                    return result
                }
            }
        }
        return nil
    }
    
    @IBAction func click(_ sender: NSOutlineView) {
        let item = sender.item(atRow: sender.clickedRow)
        let column = sender.tableColumns[sender.clickedColumn]
        if let selectedObject = self.outlineView(sender, objectValueFor: column, byItem: item) as? String,
            let item = searchKey(selectedObject, inItem: nil) {
            sender.expandItem(item)
        }
    }
}

//MARK: - NSOutlineViewDataSource
extension ViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return propertyList.count
        }
        let itemValue = (item as? (String, Any))?.1
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
        let itemValue = (item as? (String, Any))?.1
        if let dictionary = item == nil ? propertyList : (itemValue as? [String: Any]) {
            let keys = Array(dictionary.keys)
            let key = keys[index]
            let value = dictionary[key] ?? ""
            return (key, value)
        }
        if let array = (itemValue as? [String]) {
            return (array[index], "")
        }
        return ("", "")
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        if let pair = item as? (String, Any) {
            if tableColumn?.identifier == "Key" {
                return pair.0
            }
            if tableColumn?.identifier == "Value" {
                if let value = pair.1 as? [String: Any] {
                    return "Dictionary (\(value.count) elements)"
                }
                if let value = pair.1 as? [Any] {
                    return "Array (\(value.count) elements)"
                }
                return pair.1
            }
        }
        if let pair = item as? (String, String) {
            if tableColumn?.identifier == "Key" {
                return pair.0
            }
            if tableColumn?.identifier == "Value"{
                return pair.1
            }
        }
        return nil
    }
}

//MARK: - NSOutlineViewDelegate

extension ViewController: NSOutlineViewDelegate {
    
//    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
//        
//    }
    
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        if control == resultTable, let text = fieldEditor.string {
            
        }
        return true
    }
}
