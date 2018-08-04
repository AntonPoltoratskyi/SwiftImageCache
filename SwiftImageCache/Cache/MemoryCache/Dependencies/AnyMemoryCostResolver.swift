//
//  AnyMemoryCostResolver.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 28.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

/// Type eraser for MemoryCostResolver protocol
public class AnyMemoryCostResolver<Object>: MemoryCostResolver {
    
    public func cost(for object: Object) -> Int {
        fatalError("\(#function) not implemented")
    }
}

public final class AnyMemoryCostResolverBox<Resolver: MemoryCostResolver>: AnyMemoryCostResolver<Resolver.Object> {
    
    private let resolver: Resolver
    
    public init(resolver: Resolver) {
        self.resolver = resolver
    }
    
    public override func cost(for object: Resolver.Object) -> Int {
        return resolver.cost(for: object)
    }
}
