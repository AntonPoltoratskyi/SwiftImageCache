//
//  ImageCache.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 15.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

public final class ImageCache: ImageCacheInput {

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
    
    public var diskCacheSize: Int {
        return 0
    }
    
    public var discCacheCount: Int {
        return 0
    }
    
    
    // MARK: - Init
    
    public init(namespace: String, directoryURL: URL) {
        self.namespace = namespace
        self.directoryURL = directoryURL.appendingPathComponent(namespace)
        
        let config = MemoryCacheConfig()
        self.memoryCache = MemoryCache(config: config, costResolver: ImageCacheCostResolver())
    }
    
    
    // MARK: - Public API
    
    public func image(forKey key: CacheKey) -> UIImage? {
        return nil
    }
    
    public func imageFromMemory(forKey key: CacheKey) -> UIImage? {
        return nil
    }
    
    public func removeImage(forKey: CacheKey) {
        
    }
    
    public func addImage(_ image: UIImage, forKey key: CacheKey) {
        
    }
    
    public func clearMemory() {
        
    }
    
    public func clearDisk() {
        
    }
}
