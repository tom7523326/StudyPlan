//
//  Item.swift
//  StudyPlan
//
//  Created by 汤寿麟 on 2025/7/11.
//

import Foundation
import SwiftData
import SwiftUI

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
    
    var displayName: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .chinese:
            return "book.fill"
        case .math:
            return "function"
        case .english:
            return "globe"
        case .piano:
            return "pianokeys"
        }
    }
    
    var color: Color {
        switch self {
        case .chinese:
            return .blue
        case .math:
            return .green
        case .english:
            return .orange
        case .piano:
            return .purple
        }
    }
}

enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case pending = "待开始"
    case inProgress = "进行中"
    case completed = "已完成"
    case overdue = "已超时"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .pending:
            return "clock"
        case .inProgress:
            return "play.circle"
        case .completed:
            return "checkmark.circle"
        case .overdue:
            return "exclamationmark.triangle"
        }
    }
}

struct Task: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: TaskCategory
    var expectedDuration: Int
    var actualDuration: Int
    var date: Date
    var status: TaskStatus
    var startTime: Date?
    var endTime: Date?
    var note: String?
    
    init(id: UUID = UUID(), name: String, category: TaskCategory, expectedDuration: Int, actualDuration: Int = 0, date: Date, status: TaskStatus = .pending, startTime: Date? = nil, endTime: Date? = nil, note: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.expectedDuration = expectedDuration
        self.actualDuration = actualDuration
        self.date = date
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.note = note
    }
}
