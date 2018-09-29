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
    
    private let memoryCostResolver: AnyMemoryCostResolver<Value>
    
    public var maxMemoryCost: Int? {
        didSet { cache.totalCostLimit = maxMemoryCost }
    }
    
    public var maxMemoryCount: Int? {
        didSet { cache.totalCountLimit = maxMemoryCount }
    }
    
    
    // MARK: - Init
    
    init<T: MemoryCostResolver>(config: Config, memoryCostResolver: T) where T.Object == Value {
        self.config = config
        self.memoryCostResolver = AnyMemoryCostResolverBox(resolver: memoryCostResolver)
        
        cache.totalCostLimit = config.maxCacheSize
        cache.totalCountLimit = config.maxCacheItemsCount
        
        maxMemoryCost = cache.totalCostLimit
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveMemoryWarning),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
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
            let cost = memoryCostResolver.cost(for: object)
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
        
        static var `default`: Config {
            return Config(isWeakCacheEnabled: true, maxCacheItemsCount: nil, maxCacheSize: nil)
        }
        
        /// when true - cache will store weak references to currently retained cache objects
        public let isWeakCacheEnabled: Bool
        
        /// Max count of cached objects
        public let maxCacheItemsCount: Int?
        
        /// Max cache size in bytes
        public let maxCacheSize: Int?
        
        public init(isWeakCacheEnabled: Bool,
                    maxCacheItemsCount: Int?,
                    maxCacheSize: Int?) {
            self.isWeakCacheEnabled = isWeakCacheEnabled
            self.maxCacheItemsCount = maxCacheItemsCount
            self.maxCacheSize = maxCacheSize
        }
    }
}
