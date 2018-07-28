//
//  MemoryCacheConfig.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 15.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

public struct MemoryCacheConfig {
    
    /// when true - cache will store weak references to currently retained cache objects
    public let isWeakMemoryCacheEnabled: Bool
    
    /// Max cache age in seconds
    public let maxCacheAge: Int
    
    /// Max cache size in bytes
    public let maxCacheSize: Int?
    
    public init(isWeakMemoryCacheEnabled: Bool = true,
                maxCacheAge: Int = 60 * 60 * 24 * 7,
                maxCacheSize: Int? = nil) {
        self.isWeakMemoryCacheEnabled = isWeakMemoryCacheEnabled
        self.maxCacheAge = maxCacheAge
        self.maxCacheSize = maxCacheSize
    }
}
