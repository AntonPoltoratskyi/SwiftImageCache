//
//  MemoryCache.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 15.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import UIKit

public final class MemoryCache<Key: AnyObject & Hashable, Value: AnyObject> {
    
    private let config: Config
    
    /// Cache with ability to setup limits for byte size and count of objects.
    private let cache: FiniteCache<Key, Value> = FiniteCache()
    
    /// Cache that won't be cleared when memory warning occurs because values are retained by other objects.
    private let weakCache: NSMapTable<Key, Value> = NSMapTable(keyOptions: .strongMemory, valueOptions: .weakMemory)
    
    private let weakCacheLock = NSLock()
    
    private let costResolver: AnyCacheCostResolver<Value>
    
    public var maxMemoryCost: Int? {
        didSet { cache.totalCostLimit = maxMemoryCost }
    }
    
    public var maxMemoryCount: Int? {
        didSet { cache.totalCountLimit = maxMemoryCount }
    }
    
    
    // MARK: - Init
    
    init<T: CacheCostResolver>(config: Config, costResolver: T) where T.Object == Value {
        self.config = config
        self.costResolver = AnyCacheCostResolverBox(resolver: costResolver)
        
        cache.totalCostLimit = config.maxCacheSize
        cache.totalCountLimit = nil
        
        maxMemoryCost = cache.totalCostLimit
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveMemoryWarning),
                                               name: .UIApplicationDidReceiveMemoryWarning,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: - Memory Warning
    
    @objc private func didReceiveMemoryWarning() {
        cache.removeAll()
    }
    
    
    // MARK: - Public API
    
    public func setObject(_ value: Value, forKey key: Key) {
        cache.setValue(value, forKey: key)
        guard config.isWeakCacheEnabled else {
            return
        }
        weakCacheLock.lock()
        weakCache.setObject(value, forKey: key)
        weakCacheLock.unlock()
    }
    
    public func object(forKey key: Key) -> Value? {
        var object = cache.value(forKey: key)
        guard object == nil, config.isWeakCacheEnabled else {
            return object
        }
        
        weakCacheLock.lock()
        
        object = weakCache.object(forKey: key)
        if let object = object {
            let cost = costResolver.cost(for: object)
            cache.setValue(object, forKey: key, cost: cost)
        }
        
        weakCacheLock.unlock()
        
        return object
    }
    
    public func removeObject(forKey key: Key) {
        cache.removeValue(forKey: key)
        guard config.isWeakCacheEnabled else {
            return
        }
        weakCacheLock.lock()
        weakCache.removeObject(forKey: key)
        weakCacheLock.unlock()
    }
    
    public func removeAll() {
        cache.removeAll()
        guard config.isWeakCacheEnabled else {
            return
        }
        weakCacheLock.lock()
        weakCache.removeAllObjects()
        weakCacheLock.unlock()
    }
}

// MARK: - Config

extension MemoryCache {
    
    public struct Config {
        
        /// when true - cache will store weak references to currently retained cache objects
        public let isWeakCacheEnabled: Bool
        
        /// Max cache age in seconds
        public let maxCacheAge: Int
        
        /// Max cache size in bytes
        public let maxCacheSize: Int?
        
        public init(isWeakCacheEnabled: Bool = true,
                    maxCacheAge: Int = 60 * 60 * 24 * 7,
                    maxCacheSize: Int? = nil) {
            self.isWeakCacheEnabled = isWeakCacheEnabled
            self.maxCacheAge = maxCacheAge
            self.maxCacheSize = maxCacheSize
        }
    }
}
