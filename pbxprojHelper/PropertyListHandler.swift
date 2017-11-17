//
//  PropertyListHandler.swift
//  pbxprojHelper
//
//  Created by 杨萧玉 on 2016/9/25.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

import Cocoa

var applicationDocumentsDirectory: URL? {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
}

class PropertyListHandler: NSObject {
    
    /// 将工程文件内容转为字典对象
    ///
    /// - Parameter fileURL: 文件路径 URL
    /// - Returns: 字典对象，即转化后的内容
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
    
    /// 将数据内容生成为工程文件
    ///
    /// - Parameters:
    ///   - fileURL: 工程文件路径
    ///   - list: 数据对象
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
    
    /// 返回指定文件对应的备份文件路径
    ///
    /// - parameter url: 文件 URL，如果是工程文件，会被修改为 project.pbxproj 文件
    ///
    /// - returns: 备份文件路径
    fileprivate class func backupURLOf(projectURL url: inout URL) -> URL {
        var backupURL = applicationDocumentsDirectory ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents")
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
    
    /// 使用备份文件还原工程文件
    ///
    /// - Parameter fileURL: 要被还原的工程文件路径 URL
    /// - Returns:  是否还原成功
    class func recoverProject(fileURL: URL) -> Bool {
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
    
    /// 这个方法可厉（dan）害（teng）咯，把 json 配置数据应用到工程文件数据上
    ///
    /// - Parameters:
    ///   - json: 配置文件数据，用于对工程文件的增删改操作
    ///   - projectData: 工程文件数据，project.pbxproj 的内容
    ///   - isForward: 是否是正向操作
    /// - Returns: 应用 json 配置后的结果
    class func apply(json: [String: Any], onProjectData projectData: [String: Any], forward isForward: Bool = true) -> [String: Any] {
        var appliedData = projectData
        
        let operation = isForward ? "forward" : "backward"
        
        let jsonCommands: [String : [String : Any]]
        
        if let jsonContent = json[operation] as? [String : [String : Any]] {
            jsonCommands = jsonContent
        }
        else if let jsonContent = json as? [String : [String : Any]], isForward { // 兼容旧版本
            jsonCommands = jsonContent
        }
        else {
            print("json file format error! Can't support \(operation) operation! Please generate a new json file.")
            return appliedData
        }
        
        // 遍历 JSON 中的三个命令
        for (command, arguments) in jsonCommands {
            // 遍历每个命令中的路径
            for (keyPath, data) in arguments {
                let keys = keyPath.components(separatedBy: ".")
                
                /// 假如 command 为 "modify" keyPath 为 "A.B.C"，目的是让 value[A][B][C] = data。需要沿着路径深入，使用闭包修改叶子节点的数据，递归过程中逐级向上返回修改后的结果，完成整个路径上数据的更新。
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
                            // 将下一层级的修改应用到当前层级的数据
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
                
                // 调用 `walkIn` 方法，
                if let result = walkIn(atIndex: 0, withCurrentValue: appliedData, complete: { (value) -> Any? in
                    // value 为路径叶子节点的数据。根据 command 的不同，处理的规则也不一样：
                    switch command {
                        // 添加数据时 data 和 value 类型要统一，要么都是数组，要么都是字典，否则不做变更
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
                        // 移除数据时被移除的 data 为包含数据或键的数组，否则不做变更
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
                        // 直接用 data 替换 value
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
        
        /// 将两个数据对象作递归比较，将最深层次节点的差异保存到 difference 中。
        ///
        /// - Parameters:
        ///   - data1: 第一个数据对象，数组或字典
        ///   - data2: 第二个数据对象，数组或字典
        ///   - parentKeyPath: 父路径
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
    
    /// 将两个工程文件的差异保存为 JSON 文件
    ///
    /// - Parameters:
    ///   - filePath: json 文件路径
    ///   - modified: 修改过的工程文件
    ///   - original: 原始工程文件
    class func generateJSON(filePath: String, withModifiedProject modified: URL, originalProject original: URL) {
        if let modifiedPropertyList = PropertyListHandler.parseProject(fileURL: modified),
            let originalPropertyList = PropertyListHandler.parseProject(fileURL: original) {
            let jsonObjectForward = PropertyListHandler.compare(project: modifiedPropertyList, withOtherProject: originalPropertyList)
            let jsonObjectBackward = PropertyListHandler.compare(project: originalPropertyList, withOtherProject: modifiedPropertyList)
            let jsonObjectUnion = ["version": 1.0, "forward": jsonObjectForward, "backward": jsonObjectBackward]
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: jsonObjectUnion, options: .prettyPrinted)
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
    
    /// 读取 JSON 格式的文件
    ///
    /// - Parameter url: JSON 文件路径 URL
    /// - Returns: 数据对象
    class func parseJSON(fileURL url: URL) -> Any? {
        
        do {
            let jsonData = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
            return json
        } catch _ {
            return nil
        }
    }
}
