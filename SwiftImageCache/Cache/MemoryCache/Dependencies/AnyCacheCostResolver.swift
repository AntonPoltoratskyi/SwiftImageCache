//
//  AnyCacheCostResolver.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 28.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

/// Type eraser for CacheCostResolver protocol
public class AnyCacheCostResolver<Object>: CacheCostResolver {
    
    public func cost(for object: Object) -> Int {
        fatalError("\(#function) not implemented")
    }
}

public final class AnyCacheCostResolverBox<Resolver: CacheCostResolver>: AnyCacheCostResolver<Resolver.Object> {
    
    private let resolver: Resolver
    
    public init(resolver: Resolver) {
        self.resolver = resolver
    }
    
    public override func cost(for object: Resolver.Object) -> Int {
        return resolver.cost(for: object)
    }
}
