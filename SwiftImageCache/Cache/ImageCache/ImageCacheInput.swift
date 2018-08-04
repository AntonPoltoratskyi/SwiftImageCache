//
//  ImageCacheInput.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 28.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

public typealias ImageKey = URL

public protocol ImageCacheInput: class {
    var maxMemoryCost: Int? { get set }
    var maxMemoryCount: Int? { get set }
    
    var diskCacheSize: Int { get }
    var discCacheCount: Int { get }
    
    func image(forKey key: ImageKey) -> UIImage?
    func removeImage(forKey key: ImageKey)
    func addImage(_ image: UIImage, forKey key: ImageKey)
    
    func clearMemory()
    func clearDisk()
}
