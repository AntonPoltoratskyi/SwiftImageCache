//
//  ImageCache.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 15.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

typealias CacheKey = String

protocol ImageCache: class {
    var maxMemoryCost: Int? { get set }
    var maxMemoryCount: Int? { get set }
    
    var diskCacheSize: Int { get }
    var discCacheCount: Int { get }
    
    func image(forKey key: CacheKey) -> UIImage?
    func imageFromMemory(forKey key: CacheKey) -> UIImage?
    
    func removeImage(forKey: CacheKey)
    func addImage(_ image: UIImage, forKey key: CacheKey)
    
    func clearMemory()
    func clearDisk()
}

final class WebImageCache: ImageCache {

    private let namespace: String
    private let directoryURL: URL
    
    private let memoryCache: MemoryCache<NSURL, UIImage>
    
    public var maxMemoryCost: Int? {
        get { return memoryCache.maxMemoryCost }
        set { memoryCache.maxMemoryCost = newValue }
    }
    
    public var maxMemoryCount: Int? {
        get { return memoryCache.maxMemoryCount }
        set { memoryCache.maxMemoryCount = newValue }
    }
    
    var diskCacheSize: Int {
        return 0
    }
    
    var discCacheCount: Int {
        return 0
    }
    
    
    // MARK: - Init
    
    init(namespace: String, directoryURL: URL) {
        self.namespace = namespace
        self.directoryURL = directoryURL.appendingPathComponent(namespace)
        
        let config = ImageCacheConfig(isMemoryCacheEnabled: true, isWeakMemoryCacheEnabled: true)
        self.memoryCache = MemoryCache(config: config, costHandler: { $0.cacheCost })
    }
    
    
    // MARK: - Public API
    
    func image(forKey key: CacheKey) -> UIImage? {
        return nil
    }
    
    func imageFromMemory(forKey key: CacheKey) -> UIImage? {
        return nil
    }
    
    func removeImage(forKey: CacheKey) {
        
    }
    
    func addImage(_ image: UIImage, forKey key: CacheKey) {
        
    }
    
    func clearMemory() {
        
    }
    
    func clearDisk() {
        
    }
}
