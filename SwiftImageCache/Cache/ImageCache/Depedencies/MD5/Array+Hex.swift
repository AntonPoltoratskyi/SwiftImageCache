//
//  Array+Hex.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 04.08.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

extension Array where Element == UInt8 {
    
    var hexValue: String {
        return reduce(into: "") { result, byte in
            var element = String(byte, radix: 16)
            if element.count == 1 {
                element.insert("0", at: element.startIndex)
            }
            return result.append(element)
        }
    }
}
