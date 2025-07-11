//
//  Item.swift
//  StudyPlan
//
//  Created by 汤寿麟 on 2025/7/11.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
