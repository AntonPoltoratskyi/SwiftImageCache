//
//  ImageCache.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 15.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

final class ImageCache {
    
    let namespace: String
    let directoryURL: URL
    
    let memoryCache: MemoryCache<NSURL, UIImage>
    
    init(namespace: String, directoryURL: URL) {
        self.namespace = namespace
        self.directoryURL = directoryURL
        
        let config = ImageCacheConfig(isMemoryCacheEnabled: true, isWeakMemoryCacheEnabled: true)
        self.memoryCache = MemoryCache(config: config, costHandler: { $0.cacheCost })
    }
}
