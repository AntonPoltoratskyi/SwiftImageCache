//
//  Data+MD5.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 04.08.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

extension Data {
    
    var md5: Data {
        return Data(bytes: bytes.md5)
    }
    
    var bytes: [UInt8] {
        return Array(self)
    }
}
