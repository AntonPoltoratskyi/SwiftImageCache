//
//  MD5+Bytes.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 04.08.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

extension String {
    var bytes: [UInt8] {
        return data(using: .utf8, allowLossyConversion: true)?.bytes ?? Array(utf8)
    }
}

extension Data {
    var bytes: [UInt8] {
        return Array(self)
    }
}
