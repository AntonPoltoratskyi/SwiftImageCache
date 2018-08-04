//
//  Array+MD5.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 04.08.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

extension Array where Element == UInt8 {
    
    var md5: [Element] {
        return MD5().calculate(for: self)
    }
    
    var hexRepresentation: String {
        return reduce("") { result, byte in
            var s = String(byte, radix: 16)
            if s.count == 1 {
                s = "0" + s
            }
            return result + s
        }
    }
}
