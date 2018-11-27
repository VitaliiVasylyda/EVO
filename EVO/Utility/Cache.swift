//
//  Cache.swift
//  EVO
//
//  Created by Vitalii Vasylyda on 11/26/18.
//  Copyright © 2018 VitaliiVasylyda. All rights reserved.
//


import Foundation
import UIKit

struct VacuumMode : OptionSet {
    let rawValue: Int
    
    static let byDate  = VacuumMode(rawValue: 1 << 0)
    static let bySize = VacuumMode(rawValue: 1 << 1)
    static let full  = VacuumMode(rawValue: byDate.rawValue | bySize.rawValue)
}

class Cache {
    static let shared = Cache()
    
    var maxCacheSize = 524288000      // = 500MB
    var maxFileIdleLifetime = 86400.0 * 5.0     // = 24h * 5 = 5d
    
    private let vacuumInterval = 14400.0 // every 4h
    private var cacheFolderPath: String
    private var lastVacuumDate: Date?
    private var logCache = false
    
    private init() {
        
        #if DEBUG
            logCache = false
        #else
            logCache = true
        #endif
        
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        cacheFolderPath = "\(cachePath)/images/"
        
        if !FileManager.default.fileExists(atPath: cacheFolderPath) {
            try? FileManager.default.createDirectory(atPath: cacheFolderPath, withIntermediateDirectories: false, attributes: [:])
        }
        
        vacuum(mode: .full)
    }
    
    // MARK: - Vacuum
    private struct FileInfo {
        var fullPath: String
        var size: Int
        var lastModificationDate: Date
    }
    
    func vacuum(mode: VacuumMode) {
        objc_sync_enter(self)
        
        if logCache {
            print("[CACHE]: Performing cache clenup...")
        }
        
        let directoryEnumberator = FileManager.default.enumerator(atPath: cacheFolderPath)
        var cacheSize = 0
        var files = [FileInfo]()
        
        while let filePath = directoryEnumberator?.nextObject() as? String {
            let fullPath = "\(cacheFolderPath)\(filePath)"
            if logCache {
                print("[CACHE]: file found \(fullPath)")
            }
            let fileAttributes = directoryEnumberator?.fileAttributes
            
            if let attributes = fileAttributes,
                let fileSize = attributes[FileAttributeKey.size] as? Int,
                let modificationDate = attributes[FileAttributeKey.modificationDate] as? Date {
                
                if mode.contains(.byDate), -modificationDate.timeIntervalSinceNow > maxFileIdleLifetime {
                    if logCache {
                        print("[CACHE]: Date filter hit! Removing \(filePath)")
                    }
                    try? FileManager.default.removeItem(atPath: fullPath)
                } else if mode.contains(.bySize) {
                    files.append(FileInfo(fullPath: fullPath, size: fileSize, lastModificationDate: modificationDate))
                    cacheSize += fileSize
                }
            }
        }
        
        if mode.contains(.bySize), cacheSize > maxCacheSize {
            files.sort(by: { (firstFileInfo, secondFileInfo) -> Bool in
                return firstFileInfo.lastModificationDate.compare(secondFileInfo.lastModificationDate) == .orderedAscending
            })
            
            for fileInfo in files {
                if logCache {
                    print("[CACHE]: Size filter hit! Removing \(String(describing: URL(string: fileInfo.fullPath)?.lastPathComponent))")
                }
                
                do {
                    try FileManager.default.removeItem(atPath: fileInfo.fullPath)
                    cacheSize -= fileInfo.size
                } catch {
                }
                
                if cacheSize <= maxCacheSize {
                    break
                }
            }
        }
        
        lastVacuumDate = Date()
        
        objc_sync_exit(self)
    }
    
    // MARK: - Public
    func cache(image: UIImage, url: URL) {
        if image.size.width <= 0 || image.size.height <= 0 {
            return
        }
        
        if let imageData = image.pngData() {
            cache(imageData: imageData, url: url)
        }
    }
    
    func cache(imageData: Data, url: URL) {
        if imageData.count <= 0 || url.path.count <= 0 {
            return
        }
        
        if let cachedPath = cachedImagePath(url: url) {
            try? FileManager.default.removeItem(atPath: cachedPath)
            
            FileManager.default.createFile(atPath: cachedPath, contents: imageData, attributes: [:])
            if logCache {
                print("[CACHE]: image#\(url) has been successfully saved to \(cachedPath)")
            }
        }
    }
    
    func cachedImage(url: URL) -> UIImage? {
        if url.path.count > 0 {
            let imagePath = cachedImagePath(url: url)
            let image = UIImage(contentsOfFile: imagePath!)
            
            if logCache {
                print("[CACHE]: returning cached image \(String(describing: imagePath)) \(String(describing: image?.description))")
            }
            
            return image
        }
        
        return nil
    }
    
    // MARK: - Private
    func cachedImagePath(url: URL) -> String? {
        if let path = url.path.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            return "\(cacheFolderPath)image-\(path)"
        }
        
        return nil
    }
}
