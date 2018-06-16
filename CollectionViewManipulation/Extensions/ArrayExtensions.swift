//
//  ArrayExtensions.swift
//  CollectionViewManipulation
//
//  Created by Henry Miao on 16/6/18.
//  Copyright © 2018 Henry Miao. All rights reserved.
//

import Foundation

extension Array {
    
    /// Shuffle the elements
    mutating func shuffle() {
        for _ in 0..<count {
            sort { (_,_) in arc4random() < arc4random() }
        }
    }
}
