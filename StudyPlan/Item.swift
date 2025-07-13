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

enum TaskCategory: String, Codable, CaseIterable, Identifiable {
    case chinese = "语文"
    case math = "数学"
    case english = "英语"
    case piano = "钢琴"
    
    var id: String { self.rawValue }
}

enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted = "未开始"
    case inProgress = "进行中"
    case completed = "已完成"
    
    var id: String { self.rawValue }
}

struct Task: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: TaskCategory
    var expectedMinutes: Int
    var actualMinutes: Int
    var date: Date
    var status: TaskStatus
    var note: String?
    
    init(id: UUID = UUID(), name: String, category: TaskCategory, expectedMinutes: Int, actualMinutes: Int = 0, date: Date, status: TaskStatus = .notStarted, note: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.expectedMinutes = expectedMinutes
        self.actualMinutes = actualMinutes
        self.date = date
        self.status = status
        self.note = note
    }
}
