//
//  UIImage+Cache.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 15.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import UIKit

extension UIImage {
    
    var cacheCost: Int {
        return Int(size.width * size.height * scale * scale)
    }
}
