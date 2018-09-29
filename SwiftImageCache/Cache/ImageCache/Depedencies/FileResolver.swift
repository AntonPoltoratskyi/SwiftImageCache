//
//  FileResolver.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 28.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

public protocol FileResolver: class {
    func filename(for key: ImageKey) -> String
}

/// Default filename resolver with MD5 hash calculation.
final class DefaultFileResolver: FileResolver {
    
    func filename(for key: ImageKey) -> String {
        let md5 = MD5().calculate(for: key.absoluteString.bytes).hexValue
        return key.pathExtension.isEmpty ? md5 : "\(md5).\(key.pathExtension)"
    }
}
