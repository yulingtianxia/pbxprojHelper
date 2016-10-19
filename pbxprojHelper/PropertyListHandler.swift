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
        } catch let error {
            print("read project file failed. error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 返回指定文件对应的备份文件路径
    ///
    /// - parameter url: 文件 URL，如果是工程文件，会被修改为 project.pbxproj 文件
    ///
    /// - returns: 备份文件路径
    fileprivate class func backupURLOf(projectURL url: inout URL) -> URL {
        var backupURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents")
        if url.pathExtension == "xcodeproj" {
            backupURL.appendPathComponent(url.lastPathComponent)
            backupURL.appendPathExtension("project.pbxproj")
            url.appendPathComponent("project.pbxproj")
        }
        else {
            let count = url.pathComponents.count
            if count > 1 {
                backupURL.appendPathComponent(url.pathComponents[count-2])
                backupURL.appendPathExtension(url.pathComponents[count-1])
            }
        }
        backupURL.appendPathExtension("backup")
        return backupURL
    }
    
    class func generateProject(fileURL: URL, withPropertyList list: Any) {
        var url = fileURL
        let backupURL = backupURLOf(projectURL: &url)
        func handleEncode(fileURL: URL) {
            func encodeString(_ str: String) -> String {
                var result = ""
                for scalar in str.unicodeScalars {
                    if scalar.value > 0x4e00 && scalar.value < 0x9fff {
                        result += String(format: "&#%04d;", scalar.value)
                    }
                    else {
                        result += scalar.description
                    }
                }
                return result
            }
            do {
                var txt = try String(contentsOf: fileURL, encoding: .utf8)
                txt = encodeString(txt)
                try txt.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch let error {
                print("translate chinese characters to mathematical symbols error: \(error.localizedDescription)")
            }
        }
        
        do {
            if FileManager().fileExists(atPath: backupURL.path) {
                try FileManager().removeItem(at: backupURL)
            }
            try FileManager().moveItem(at: url, to: backupURL)
            print("backupURL: \(backupURL)")
            let data = try PropertyListSerialization.data(fromPropertyList: list, format: .xml, options: 0)
            try data.write(to: url, options: .atomic)
            handleEncode(fileURL: url)
        } catch let error {
            do {
                print("generate new project file failed: \(error.localizedDescription), try to roll back project file!")
                try FileManager().moveItem(at: backupURL, to: url)
            } catch _ {
                print("roll back project file failed! backup file url: \(backupURL), error: \(error.localizedDescription)")
            }
        }
    }
    
    class func revertProject(fileURL: URL) -> Bool {
        var url = fileURL
        let backupURL = backupURLOf(projectURL: &url)
        do {
            if FileManager().fileExists(atPath: backupURL.path) {
                if FileManager().fileExists(atPath: url.path) {
                    try FileManager().removeItem(at: url)
                }
                try FileManager().moveItem(at: backupURL, to: url)
                return true
            }
            else {
                print("could not find backups")
                return false
            }
        } catch let error {
            print("roll back project file failed! backup file url: \(backupURL), error: \(error.localizedDescription)")
            return false
        }
    }
    
    class func parseJSON(fileURL url: URL) -> Any? {
        
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
    class func apply(json: [String: [String: Any]], onProjectData projectData: [String: Any]) -> [String: Any] {
        var appliedData = projectData
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
                    return value
                }
                
                if let result = walkIn(atIndex: 0, withCurrentValue: appliedData, complete: { (value) -> Any? in
                    
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
                        return value
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
                        if var array = value as? [String],
                            let arrayData = data as? [Any] {
                            for removeData in arrayData {
                                if let removeIndex = removeData as? Int {
                                    if (0 ..< array.count).contains(removeIndex) {
                                        array.remove(at: removeIndex)
                                    }
                                }
                                if let removeElement = removeData as? String,
                                    let removeIndex = array.index(of: removeElement) {
                                    array.remove(at: removeIndex)
                                }
                            }
                            return array
                        }
                        return value
                    case "modify":
                        return data
                    default:
                        return value
                    }
                    
                }) as? [String: Any] {
                    appliedData = result
                }
            }
        }
        return appliedData
    }
    
    /// 将 project 与 other project 做比较
    ///
    /// - parameter project1: 作为比较的 project
    /// - parameter project2: 被参照的 project
    ///
    /// - returns: project1 相对于 project2 的变化
    class func compare(project project1: [String: Any], withOtherProject project2: [String: Any]) -> Any {
        
        var difference = ["insert": [String: Any](), "remove": [String: Any](), "modify": [String: Any]()]
        
        func compare(data data1: Any?, withOtherData data2: Any?, parentKeyPath: String) {
            if let dictionary1 = data1 as? [String: Any], let dictionary2 = data2 as? [String: Any] {
                let set1 = Set(dictionary1.keys)
                let set2 = Set(dictionary2.keys)
                for key in set1.subtracting(set2) {
                    if let value = dictionary1[key], difference["insert"]?[parentKeyPath] == nil {
                        difference["insert"]?[parentKeyPath] = [key: value]
                    }
                    else if let value = dictionary1[key], var insertDictionary = difference["insert"]?[parentKeyPath] as? [String: Any] {
                        insertDictionary[key] = value
                        difference["insert"]?[parentKeyPath] = insertDictionary
                    }
                }
                for key in set2.subtracting(set1) {
                    if difference["remove"]?[parentKeyPath] == nil {
                        difference["remove"]?[parentKeyPath] = [key]
                    }
                    else if var removeArray = difference["remove"]?[parentKeyPath] as? [Any] {
                        removeArray.append(key)
                        difference["remove"]?[parentKeyPath] = removeArray
                    }
                }
                for key in set1.intersection(set2) {
                    let keyPath = parentKeyPath == "" ? key : "\(parentKeyPath).\(key)"
                    // values are both String, leaf node
                    if let str1 = dictionary1[key] as? String,
                        let str2 = dictionary2[key] as? String {
                        if str1 != str2 {
                            difference["modify"]?[keyPath] = str1
                        }
                    }
                    else { // continue compare subtrees
                        compare(data: dictionary1[key], withOtherData: dictionary2[key], parentKeyPath: keyPath)
                    }
                }
            }
            if let array1 = data1 as? [String], let array2 = data2 as? [String] {
                let set1 = Set(array1)
                let set2 = Set(array2)
                for element in set1.subtracting(set2) {
                    if difference["insert"]?[parentKeyPath] == nil {
                        difference["insert"]?[parentKeyPath] = [element]
                    }
                    else if var insertArray = difference["insert"]?[parentKeyPath] as? [Any] {
                        insertArray.append(element)
                        difference["insert"]?[parentKeyPath] = insertArray
                    }
                }
                for element in set2.subtracting(set1) {
                    if difference["remove"]?[parentKeyPath] == nil {
                        difference["remove"]?[parentKeyPath] = [element]
                    }
                    else if var removeArray = difference["remove"]?[parentKeyPath] as? [Any] {
                        removeArray.append(element)
                        difference["remove"]?[parentKeyPath] = removeArray
                    }
                }
            }
        }
        compare(data: project1, withOtherData: project2, parentKeyPath: "")
        return difference
    }
    
    class func generateJSON(filePath: String, withModifiedProject modified: URL, originalProject original: URL) {
        if let modifiedPropertyList = PropertyListHandler.parseProject(fileURL: modified),
            let originalPropertyList = PropertyListHandler.parseProject(fileURL: original) {
            let jsonObject = PropertyListHandler.compare(project: modifiedPropertyList, withOtherProject: originalPropertyList)
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                var jsonURL = URL(fileURLWithPath: filePath)
                if jsonURL.pathExtension != "json" {
                    jsonURL.appendPathComponent("JsonConfiguration.json")
                }
                try jsonData.write(to: jsonURL, options: .atomic)
            } catch let error {
                print("generate json file error: \(error.localizedDescription)")
            }
        }
    }
}
