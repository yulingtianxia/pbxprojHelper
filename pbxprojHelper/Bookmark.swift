//
//  Bookmark.swift
//  pbxprojHelper
//
//  Created by 杨萧玉 on 2017/11/14.
//  Copyright © 2017年 杨萧玉. All rights reserved.
//

import Foundation
import Cocoa

var bookmarks = [URL: Data]()

var applicationDocumentsDirectory: URL? {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
}

func bookmarkPath() -> String? {
    return applicationDocumentsDirectory?.appendingPathComponent("Bookmarks.dict").path
}

func loadBookmarks() {
    if let path = bookmarkPath(), let unarchiveData = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? [URL: Data] {
        bookmarks = unarchiveData
        for bookmark in bookmarks {
            restoreBookmark(bookmark)
        }
    }
}

func saveBookmarks() {
    if let path = bookmarkPath() {
        NSKeyedArchiver.archiveRootObject(bookmarks, toFile: path)
    }
}

func storeBookmark(url: URL) {
    do {
        let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        bookmarks[url] = data
    } catch let error {
        print ("Error storing bookmarks: \(error.localizedDescription)")
    }
}

func restoreBookmark(_ bookmark: (key: URL, value: Data)) {
    let restoredURL: URL?
    var isStale = false
    
    print ("Restoring \(bookmark.key)")
    do {
        restoredURL = try URL.init(resolvingBookmarkData: bookmark.value, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
    }
    catch let error {
        print ("Error restoring bookmarks: \(error.localizedDescription)")
        restoredURL = nil
    }
    
    if let url = restoredURL {
        if isStale {
            print ("URL is stale")
        }
        else {
            if !url.startAccessingSecurityScopedResource() {
                print ("Couldn't access: \(url.path)")
            }
        }
    }
}
