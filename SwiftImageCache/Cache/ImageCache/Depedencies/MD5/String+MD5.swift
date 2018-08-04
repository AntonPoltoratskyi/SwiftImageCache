//
//  String+MD5.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 04.08.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

extension String {
    
    var bytes: [UInt8] {
        return data(using: String.Encoding.utf8, allowLossyConversion: true)?.bytes ?? Array(utf8)
    }
    
    var md5: String {
        return bytes.md5.hexRepresentation
    }
}
