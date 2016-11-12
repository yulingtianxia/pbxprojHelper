//
//  Utils.swift
//  pbxprojHelper
//
//  Created by 杨萧玉 on 2016/11/12.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

import Foundation

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
    
    var countLimit:Int = 0
    
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
