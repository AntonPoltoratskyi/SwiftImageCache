//
//  ImageEncoder.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 31.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import UIKit

public protocol ImageEncoder: class {
    func encode(image: UIImage) -> Data?
}

/// Supports default 'jpeg' and 'png' format.
public final class DefaultImageEncoder: ImageEncoder {
    
    public func encode(image: UIImage) -> Data? {
        return UIImagePNGRepresentation(image)
    }
}
