//
//  ImageCacheInput.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 28.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

public typealias ImageCacheKey = URL

public protocol ImageCacheInput: class {
    var maxMemoryCost: Int? { get set }
    var maxMemoryCount: Int? { get set }
    
    var diskCacheSize: Int { get }
    var discCacheCount: Int { get }
    
    func image(forKey key: ImageCacheKey) -> UIImage?
    func removeImage(forKey key: ImageCacheKey)
    func addImage(_ image: UIImage, forKey key: ImageCacheKey)
    
    func clearMemory()
    func clearDisk()
}
