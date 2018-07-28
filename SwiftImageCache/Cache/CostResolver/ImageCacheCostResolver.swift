//
//  ImageCacheCostResolver.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 28.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import UIKit

final class ImageCacheCostResolver: CacheCostResolver {
    
    func cost(for object: UIImage) -> Int {
        let scale = object.scale
        let width = object.size.width * scale
        let height = object.size.height * scale
        return Int(width * height)
    }
}
