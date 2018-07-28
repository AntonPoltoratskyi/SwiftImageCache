//
//  CacheCostResolver.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 28.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

protocol CacheCostResolver {
    associatedtype Object
    func cost(for object: Object) -> Int
}