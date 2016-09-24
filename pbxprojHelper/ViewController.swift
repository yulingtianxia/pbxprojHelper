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
}

extension ViewController: NSTextFieldDelegate {
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        if control == filePathTF {
            if let data = PropertyListHandler.parseFilePath(filePathTF.stringValue) {
                propertyList = data;
                resultTable.reloadData()
            }
        }
        return true
    }
}

//MARK: - NSOutlineViewDataSource
extension ViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return propertyList.keys.count
        }
        else {
            return (item as? [String: Any])?.count ?? 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return item is [String: Any]
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let parent = item ?? propertyList
        if let values = (parent as? [String: Any])?.values {
            let value = Array(values)[index]
            if value is [String: Any] {
                return value
            }
            else {
                if let keys = (parent as? [String: Any])?.keys {
                    let key = Array(keys)[index]
                    return (key, value)
                }
            }
        }
        return "error"
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        if item is [String: Any] {
            if tableColumn?.identifier == "Key" {
                return (item as? (String, Any))?.0
            }
        }
        else if item is (String, Any) {
            if tableColumn?.identifier == "Key" {
                return (item as? (String, Any))?.0
            }
            else {
                return (item as? (String, Any))?.1
            }
        }
        return nil
    }
}
