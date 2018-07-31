//
//  FiniteCache.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 15.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

/*
 Inspired by open source NSCache implementation:
 https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/NSCache.swift
 But own implementation is compatible with Swift value types.
 */
public final class FiniteCache<Key: Hashable, Value> {
    
    private final class Entry {
        var key: Key
        var value: Value
        var cost: Int
        var next: Entry?
        var previous: Entry?
        
        init(key: Key, value: Value, cost: Int) {
            self.key = key
            self.value = value
            self.cost = cost
        }
    }
    
    private var entries: [Key: Entry] = [:]
    private var totalCost = 0
    private var head: Entry?
    private let lock = NSLock()
    
    public var totalCostLimit: Int?
    public var totalCountLimit: Int?
 
    
    // MARK: - Init
    
    public init() { }
    
    
    // MARK: - Public
    
    public func value(forKey key: Key) -> Value? {
        lock.lock()
        let result = entries[key]?.value
        lock.unlock()
        return result
    }
    
    public func setValue(_ value: Value, forKey key: Key, cost: Int = 0) {
        let newCost = max(cost, 0)
        
        lock.lock()
        
        let costDiff: Int
        
        if let entry = entries[key] {
            costDiff = newCost - entry.cost
            
            entry.cost = newCost
            entry.value = value
            
            if costDiff != 0 {
                remove(entry)
                insert(entry)
            }
        } else {
            costDiff = newCost
            
            let entry = Entry(key: key, value: value, cost: newCost)
            entries[key] = entry
            insert(entry)
        }
        
        totalCost += costDiff
        
        trimToLimits()
        
        lock.unlock()
    }
    
    public func removeValue(forKey key: Key) {
        lock.lock()
        
        if let entry = entries.removeValue(forKey: key) {
            totalCost -= entry.cost
            remove(entry)
        }
        
        lock.unlock()
    }
    
    public func removeAll() {
        lock.lock()
        entries.removeAll()
        
        while let currentElement = head {
            let nextElement = currentElement.next
            
            currentElement.previous = nil
            currentElement.next = nil
            
            head = nextElement
        }
        
        totalCost = 0
        lock.unlock()
    }
    
    
    // MARK: - Private
    
    // MARK: Storage Limitation
    
    private func trimToLimits() {
        func clear(_ entry: Entry) {
            totalCost -= entry.cost
            
            // self.head will be changed to next entry in remove(_:)
            remove(entry)
            entries[entry.key] = nil
        }
        
        if let totalCostLimit = totalCostLimit {
            var purgeAmount = totalCost - totalCostLimit
            while purgeAmount > 0 {
                guard let entry = head else {
                    break
                }
                purgeAmount -= entry.cost
                clear(entry)
            }
        }
        
        if let totalCountLimit = totalCountLimit {
            var purgeCount = entries.count - totalCountLimit
            while purgeCount > 0 {
                guard let entry = head else {
                    break
                }
                purgeCount -= 1
                clear(entry)
            }
        }
    }
    
    // MARK: Linked List
    
    private func insert(_ entry: Entry) {
        guard var currentElement = head else {
            // The cache is empty
            entry.previous = nil
            entry.next = nil
            
            head = entry
            return
        }
        
        guard entry.cost > currentElement.cost else {
            // Insert entry at the head
            entry.previous = nil
            entry.next = currentElement
            currentElement.previous = entry
            
            head = entry
            return
        }
        
        while let nextByCost = currentElement.next, nextByCost.cost < entry.cost {
            currentElement = nextByCost
        }
        
        // Insert entry between currentElement and nextElement
        let nextElement = currentElement.next
        
        currentElement.next = entry
        entry.previous = currentElement
        
        entry.next = nextElement
        nextElement?.previous = entry
    }
    
    private func remove(_ entry: Entry) {
        let oldPrev = entry.previous
        let oldNext = entry.next
        
        oldPrev?.next = oldNext
        oldNext?.previous = oldPrev
        
        if entry === head {
            head = oldNext
        }
    }
}
