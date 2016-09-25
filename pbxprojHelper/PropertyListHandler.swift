//
//  PropertyListHandler.swift
//  pbxprojHelper
//
//  Created by 杨萧玉 on 2016/9/25.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

import Cocoa

class PropertyListHandler: NSObject {
    class func parseProjectFileURL(_ fileURL: URL) -> [String: Any]? {
        var url = fileURL
        if url.pathExtension == "xcodeproj" {
            url.appendPathComponent("project.pbxproj")
        }
        
        do {
            let fileData = try Data(contentsOf: url)
            let plist = try PropertyListSerialization.propertyList(from: fileData, options: .mutableContainersAndLeaves, format: nil)
            return plist as? [String:Any]
        } catch _ {
            return nil
        }
    }
    
    class func parseJSONFileURL(_ url: URL) -> Any? {
        
        do {
            let jsonData = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
            return json
        } catch _ {
            return nil
        }
    }
    
    class func apply(json: [String: [String: Any]], onProjectData projectData: inout [String: Any]) {
        for (command, arguments) in json {
            for (keyPath, data) in arguments {
                let keys = keyPath.components(separatedBy: ".")

                func walkIn(atIndex index: Int, withCurrentValue value: Any, complete: (Any) -> Any?) -> Any? {
                    if index < keys.count {
                        let key = keys[index]
                        if let dicValue = value as? [String: Any],
                            let nextValue = dicValue[key] {
                            var resultValue = dicValue
                            resultValue[key] = walkIn(atIndex: index + 1, withCurrentValue: nextValue, complete: complete)
                            return resultValue
                        }
                    }
                    else {
                        return complete(value)
                    }
                    return nil
                }
                switch command {
                case "insert":
                    if let result = walkIn(atIndex: 0, withCurrentValue: projectData, complete: { (value) -> Any? in
                        if var dictionary = value as? [String: Any],
                            let dicData = data as? [String: Any] {
                            for (dataKey, dataValue) in dicData {
                                dictionary[dataKey] = dataValue
                            }
                            return dictionary
                        }
                        if var array = value as? [Any],
                            let arrayData = data as? [Any] {
                            array.append(contentsOf: arrayData)
                            return array
                        }
                        return nil
                    }) as? [String: Any] {
                        projectData = result
                    }
                case "remove": break
//                    TODO:
                case "modify": break
//                    TODO:
                default:
                    print("")
                }
            }
        }
    }
}
