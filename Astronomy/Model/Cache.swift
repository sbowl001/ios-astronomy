//
//  Cache.swift
//  Astronomy
//
//  Created by Stephanie Bowles on 8/14/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation

class Cache<Key: Hashable, Value> {
    private var cachedItems: [Key: Value] = [:]
    private let queue = DispatchQueue(label: "SerialQueue")
//    Create a private property that is a dictionary to be used to actually store the cached items. The type of the dictionary should be [Key : Value]. Make sure you initialize it with an empty dictionary.
    func cache(value: Value, for key: Key) {
        queue.sync {
            self.cachedItems[key] = value
        }
    }
    
    func value(key: Key) -> Value? {
        return queue.sync {
            self.cachedItems[key]
        }
    }
    
    
}
