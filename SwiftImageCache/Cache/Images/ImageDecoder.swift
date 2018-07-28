//
//  ImageDecoder.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 29.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import UIKit

public protocol ImageDecoder: class {
    func image(from data: Data) -> UIImage?
}

final class DefaultImageDecoder: ImageDecoder {
    
    func image(from data: Data) -> UIImage? {
        return UIImage(data: data, scale: UIScreen.main.scale)
    }
}
