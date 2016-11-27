//
//  Utils.swift
//  pbxprojHelper
//
//  Created by 杨萧玉 on 2016/11/12.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

import Cocoa

typealias Item = (key: String, value: Any, parent: Any?)

func isItem(_ item: Any, containsKeyWord word: String) -> Bool {
    func checkAny(value: Any, containsString string: String) -> Bool {
        return ((value is String) && (value as! String).lowercased().contains(string.lowercased()))
    }
    if let tupleItem = item as? Item {
        if checkAny(value: tupleItem.key, containsString: word) || checkAny(value: tupleItem.value, containsString: word) {
            return true
        }
        func dfs(propertyList list: Any) -> Bool {
            if let dictionary = list as? [String: Any] {
                for (key, value) in dictionary {
                    if checkAny(value: key, containsString: word) || checkAny(value: value, containsString: word) {
                        return true
                    }
                    else if dfs(propertyList: value) {
                        return true
                    }
                }
            }
            if let array = list as? [Any] {
                for value in array {
                    if checkAny(value: value, containsString: word) {
                        return true
                    }
                    else if dfs(propertyList: value) {
                        return true
                    }
                }
            }
            return false
        }
        return dfs(propertyList: tupleItem.value)
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

var recentUsePaths = LRUCache <String, String>()

class CacheGenerator<T:Hashable> : IteratorProtocol {
    
    typealias Element = T
    
    var counter: Int
    let array:[T]
    
    init(keys:[T]) {
        counter = 0
        array = keys
    }
    
    func next() -> Element? {
        let result:Element? = counter < array.count ? array[counter] : nil
        counter += 1
        return result
    }
}

class LRUCache <K:Hashable, V> : NSObject, NSCoding, Sequence {
    
    fileprivate var _cache = [K:V]()
    fileprivate var _keys = [K]()
    
    var countLimit: Int = 0
    var count: Int {
        get {
            return _keys.count
        }
    }
    
    override init() {
        
    }
    
    subscript(index:Int) -> K {
        get {
            return _keys[index]
        }
    }
    
    subscript(key:K) -> V? {
        get {
            return _cache[key]
        }
        set(obj) {
            if obj == nil {
                _cache.removeValue(forKey: key)
            }
            else {
                useKey(key)
                _cache[key] = obj
            }
        }
    }
    
    fileprivate func useKey(_ key: K) {
        if let index = _keys.index(of: key) {// key 已存在数组中，只需要将其挪至 index 0
            _keys.insert(_keys.remove(at: index), at: 0)
        }
        else {// key 不存在数组中，需要将其插入 index 0，并在超出缓存大小阈值时移走最后面的元素
            if _keys.count >= countLimit {
                _cache.removeValue(forKey: _keys.last!)
                _keys.removeLast()
            }
            _keys.insert(key, at: 0)
        }
    }
    
    typealias Iterator = CacheGenerator<K>
    
    func makeIterator() -> Iterator {
        return CacheGenerator(keys:_keys)
    }
    
    func cleanCache() {
        _cache.removeAll()
        _keys.removeAll()
    }
    
    // NSCoding
    @objc required init?(coder aDecoder: NSCoder) {
        _keys = aDecoder.decodeObject(forKey: "keys") as! [K]
        _cache = aDecoder.decodeObject(forKey: "cache") as! [K:V]
    }
    
    @objc func encode(with aCoder: NSCoder) {
        aCoder.encode(_keys, forKey: "keys")
        aCoder.encode(_cache, forKey: "cache")
    }
    
}

func writePasteboard(_ location: String) {
    NSPasteboard.general().declareTypes([NSStringPboardType], owner: nil)
    NSPasteboard.general().setString(location, forType: NSStringPboardType)
}
