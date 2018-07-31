//
//  ImageEncoder.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 31.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

public protocol ImageEncoder: class {
    func encode(image: UIImage) -> Data?
}

public final class PNGImageEncoder: ImageEncoder {

    public func encode(image: UIImage) -> Data? {
        return UIImagePNGRepresentation(image)
    }
}

public final class JPEGImageEncoder: ImageEncoder {
    
    public func encode(image: UIImage) -> Data? {
        return UIImageJPEGRepresentation(image, 1)
    }
}
