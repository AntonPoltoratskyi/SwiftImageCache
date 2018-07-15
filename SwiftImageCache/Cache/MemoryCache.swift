//
//  MemoryCache.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 15.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import UIKit

public final class MemoryCache {
    
    let config: ImageCacheConfig
    let cache: FiniteCache<URL, UIImage>
    
    
    // MARK: - Init
    
    public init(config: ImageCacheConfig) {
        self.config = config
        cache = FiniteCache()
        cache.totalCostLimit = config.maxCacheSize
        cache.totalCountLimit = nil
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveMemoryWarning),
                                               name: .UIApplicationDidReceiveMemoryWarning,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: - Notifications
    
    @objc private func didReceiveMemoryWarning() {
        cache.removeAll()
    }
}
