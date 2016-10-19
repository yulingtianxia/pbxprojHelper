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
    @IBOutlet weak var chooseJSONFileBtn: NSButton!
    
    
    var propertyListURL: URL?
    var jsonFileURL: URL?
    var filterKeyWord = ""
    
    var originalPropertyList: [String: Any] = [:]
    var currentPropertyList: [String: Any] = [:]
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func isItem(_ item: Any, containsKeyWord word: String) -> Bool {
        func checkAny(value: Any, containsString string: String) -> Bool {
            return ((value is String) && (value as! String).lowercased().contains(string.lowercased()))
        }
        if let tupleItem = item as? Item {
            if checkAny(value: tupleItem.key, containsString: word) || checkAny(value: tupleItem.value, containsString: word) {
                return true
            }
            func tfs(propertyList list: Any) -> Bool {
                if let dictionary = list as? [String: Any] {
                    for (key, value) in dictionary {
                        if checkAny(value: key, containsString: word) || checkAny(value: value, containsString: word) {
                            return true
                        }
                        else if tfs(propertyList: value) {
                            return true
                        }
                    }
                }
                if let array = list as? [Any] {
                    for value in array {
                        if checkAny(value: value, containsString: word) {
                            return true
                        }
                        else if tfs(propertyList: value) {
                            return true
                        }
                    }
                }
                return false
            }
            return tfs(propertyList: tupleItem.value)
        }
        return false
    }
    
    func elementsOfDictionary(_ dictionary: [String: Any], containsKeyWord word: String) -> [String: Any] {
        var filtResult = [String: Any]()
        for (key, value) in dictionary {
            if isItem(Item(key: key, value: value, parent: nil), containsKeyWord: word) {
                filtResult[key] = value
            }
        }
        return filtResult
    }
    
    func elementsOfArray(_ array: [Any], containsKeyWord word: String) -> [Any] {
        return array.filter { isItem(Item(key: "", value: $0, parent: nil), containsKeyWord: word) }
    }

    func keyPath(forItem item: Any?) -> String {
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
                originalPropertyList = [:]
                currentPropertyList = [:]
                if let data = PropertyListHandler.parseProject(fileURL: url) {
                    originalPropertyList = data
                    currentPropertyList = data
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
                let data = PropertyListHandler.parseJSON(fileURL: url) as? [String: [String: Any]] {
                jsonFileURL = url
                currentPropertyList = PropertyListHandler.apply(json: data, onProjectData: originalPropertyList)
                chooseJSONFileBtn.title = url.lastPathComponent
                resultTable.reloadData()
            }
        }
    }
    
    @IBAction func applyJSONConfiguration(_ sender: NSButton) {
        if let propertyURL = propertyListURL, let jsonURL = jsonFileURL {
            if let propertyListData = PropertyListHandler.parseProject(fileURL: propertyURL),
                let jsonFileData = PropertyListHandler.parseJSON(fileURL: jsonURL) as? [String: [String: Any]]{
                originalPropertyList = propertyListData
                currentPropertyList = PropertyListHandler.apply(json: jsonFileData, onProjectData: originalPropertyList)
                resultTable.reloadData()
            }
            DispatchQueue.global().async {
                PropertyListHandler.generateProject(fileURL: propertyURL, withPropertyList: self.currentPropertyList)
            }
        }
    }
    
    @IBAction func revertPropertyList(_ sender: NSButton) {
        if let url = propertyListURL {
            if PropertyListHandler.revertProject(fileURL: url), let data = PropertyListHandler.parseProject(fileURL: url) {
                originalPropertyList = data
                currentPropertyList = data
            }
            else {
                currentPropertyList = originalPropertyList
            }
            chooseJSONFileBtn.title = "Choose JSON File"
            resultTable.reloadData()
        }
    }
    
    @IBAction func click(_ sender: NSOutlineView) {
        if sender.clickedRow >= 0 && sender.clickedColumn >= 0 {
            let item = sender.item(atRow: sender.clickedRow)
            let column = sender.tableColumns[sender.clickedColumn]
            if let selectedString = self.outlineView(sender, objectValueFor: column, byItem: item) as? String {
                writePasteboard(selectedString)
            }
        }
    }
    
    @IBAction func doubleClick(_ sender: NSOutlineView) {
        if sender.selectedRow >= 0 {
            let item = sender.item(atRow: sender.clickedRow)
            let path = keyPath(forItem: item)
            writePasteboard(path)
        }
    }
}

//MARK: - NSOutlineViewDataSource
extension ViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            if filterKeyWord != "" {
                return elementsOfDictionary(currentPropertyList, containsKeyWord: filterKeyWord).count
            }
            return currentPropertyList.count
        }
        
        let itemValue = (item as? Item)?.value
        if let dictionary = itemValue as? [String: Any] {
            if filterKeyWord != "" && !((item as? Item)?.key.lowercased().contains(filterKeyWord.lowercased()) ?? false) {
                return elementsOfDictionary(dictionary, containsKeyWord: filterKeyWord).count
            }
            return dictionary.count
        }
        if let array = itemValue as? [Any] {
            if filterKeyWord != "" && !((item as? Item)?.key.lowercased().contains(filterKeyWord.lowercased()) ?? false) {
                return elementsOfArray(array, containsKeyWord: filterKeyWord).count
            }
            return array.count
        }
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return self.outlineView(outlineView, numberOfChildrenOfItem: item) > 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let itemValue = (item as? Item)?.value
        if var dictionary = item == nil ? currentPropertyList : (itemValue as? [String: Any]) {
            if filterKeyWord != "" && !((item as? Item)?.key.lowercased().contains(filterKeyWord.lowercased()) ?? false) {
                dictionary = elementsOfDictionary(dictionary, containsKeyWord: filterKeyWord)
            }
            let keys = Array(dictionary.keys)
            let key = keys[index]
            let value = dictionary[key] ?? ""
            let childItem = Item(key: key, value: value, parent: item)
            return childItem
        }
        if var array = (itemValue as? [String]) {
            if filterKeyWord != "" && !((item as? Item)?.key.lowercased().contains(filterKeyWord.lowercased()) ?? false) {
                array = elementsOfArray(array, containsKeyWord: filterKeyWord) as! [String]
            }
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
        if let text = fieldEditor.string {
            filterKeyWord = text
            resultTable.reloadData()
            resultTable.expandItem(nil, expandChildren: true)
        }
        return true
    }
}
