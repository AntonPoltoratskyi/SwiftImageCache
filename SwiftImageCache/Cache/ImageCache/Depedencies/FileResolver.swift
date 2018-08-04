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

final class DefaultFileResolver: FileResolver {
    
    func filename(for key: ImageKey) -> String {
        let string = key.absoluteString
        let fileExtension = key.pathExtension
        return fileExtension.isEmpty ? string.md5 : "\(string.md5).\(fileExtension)"
    }
}
