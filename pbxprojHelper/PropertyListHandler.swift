//
//  PropertyListHandler.swift
//  pbxprojHelper
//
//  Created by 杨萧玉 on 2016/9/25.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

import Cocoa

class PropertyListHandler: NSObject {
    
    class func parseProject(fileURL: URL) -> [String: Any]? {
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
    
    class func generateProject(fileURL: URL, withPropertyList list: Any) {
        var url = fileURL
        if url.pathExtension == "xcodeproj" {
            url.appendPathComponent("project.pbxproj")
        }
        let backupURL = url.appendingPathExtension("backup")
        do {
            if FileManager().fileExists(atPath: backupURL.path) {
                try FileManager().removeItem(at: backupURL)
            }
            try FileManager().moveItem(at: url, to: backupURL)
            let data = try PropertyListSerialization.data(fromPropertyList: list, format: .xml, options: 0)
            try data.write(to: url, options: .atomic)
        } catch let error {
            do {
                print("generate new project file failed: \(error.localizedDescription), try to roll back project file!")
                try FileManager().moveItem(at: backupURL, to: url)
            } catch _ {
                print("roll back project file failed! backup file url: \(backupURL)")
            }
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
    
    /// 这个方法可厉（dan）害（teng）咯，把 json 配置数据应用到工程文件数据上
    ///
    /// - parameter json:        配置文件数据，用于对工程文件的增删改操作
    /// - parameter projectData: 工程文件数据，project.pbxproj 的内容
    class func apply(json: [String: [String: Any]], onProjectData projectData: inout [String: Any]) {
        for (command, arguments) in json {
            for (keyPath, data) in arguments {
                let keys = keyPath.components(separatedBy: ".")
                
                /// 沿着路径深入，使用闭包修改叶子节点的数据，递归过程中逐级向上返回修改结果，完成整个路径上数据的更新
                ///
                /// - parameter index:    路径深度
                /// - parameter value:    当前路径对应的值
                /// - parameter complete: 路径终点所要做的操作
                ///
                /// - returns: 当前路径层级修改后的值
                func walkIn(atIndex index: Int, withCurrentValue value: Any, complete: (Any) -> Any?) -> Any? {
                    if index < keys.count {
                        let key = keys[index]
                        if let dicValue = value as? [String: Any],
                            let nextValue = dicValue[key] {
                            var resultValue = dicValue
                            resultValue[key] = walkIn(atIndex: index + 1, withCurrentValue: nextValue, complete: complete)
                            return resultValue
                        }
                        else {
                            print("Wrong KeyPath")
                        }
                    }
                    else {
                        return complete(value)
                    }
                    return nil
                }
                
                if let result = walkIn(atIndex: 0, withCurrentValue: projectData, complete: { (value) -> Any? in
                    
                    switch command {
                    case "insert":
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
                    case "remove":
                        if var dictionary = value as? [String: Any],
                            let arrayData = data as? [Any] {
                            for removeData in arrayData {
                                if let removeKey = removeData as? String {
                                    dictionary[removeKey] = nil
                                }
                            }
                            return dictionary
                        }
                        if var array = value as? [Any],
                            let arrayData = data as? [Any] {
                            for removeData in arrayData {
                                if let removeIndex = removeData as? Int {
                                    if (0 ..< array.count).contains(removeIndex) {
                                        array.remove(at: removeIndex)
                                    }
                                }
                            }
                            return array
                        }
                        return nil
                    case "modify":
                        return data
                    default:
                        return projectData
                    }
                    
                }) as? [String: Any] {
                    projectData = result
                }
            }
        }
    }
}
