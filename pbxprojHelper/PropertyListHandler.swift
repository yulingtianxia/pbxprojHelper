//
//  PropertyListHandler.swift
//  pbxprojHelper
//
//  Created by 杨萧玉 on 2016/9/25.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

import Cocoa

class PropertyListHandler: NSObject {
    class func parseFilePath(_ filePath: String) -> [String: Any]? {
        let url = URL(fileURLWithPath: filePath)
        
        do {
            let fileData = try Data(contentsOf: url)
            let plist = try PropertyListSerialization.propertyList(from: fileData, options: .mutableContainersAndLeaves, format: nil)
            return plist as? [String:Any]
        } catch _ {
            return nil
        }
    }
}
