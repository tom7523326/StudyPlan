//
//  StudyPlanApp.swift
//  StudyPlan
//
//  Created by 汤寿麟 on 2025/7/11.
//

import SwiftUI
import SwiftData

class TaskStore: ObservableObject {
    @Published var tasks: [Task] = [] {
        didSet {
            saveTasks()
        }
    }
    
    init() {
        loadInitialTasks()
        loadSavedTasks()
    }
    
    func loadInitialTasks() {
        let templateTasks: [(String, TaskCategory, Int)] = [
            ("同步练字帖（三张）", .chinese, 20),
            ("阅读人文天天练（一篇）", .chinese, 10),
            ("同步作文（三天写两篇）", .chinese, 30),
            ("每次读书40分钟，抄好句子", .chinese, 40),
            ("数感小超市（每日一篇）", .math, 10),
            ("数学探物（每日一主题）", .math, 20),
            ("斑马1天2集", .english, 30),
            ("术语三遍", .piano, 10),
            ("自我介绍3遍", .piano, 10)
        ]
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 7, day: 12))!
        let endDate = calendar.date(from: DateComponents(year: 2025, month: 8, day: 10))!
        var allTasks: [Task] = []
        var date = startDate
        while date <= endDate {
            for tpl in templateTasks {
                allTasks.append(Task(
                    name: tpl.0,
                    category: tpl.1,
                    expectedMinutes: tpl.2,
                    actualMinutes: 0,
                    date: date,
                    status: .notStarted
                ))
            }
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        self.tasks = allTasks
    }
    
    private let tasksKey = "StudyPlanTasksV1"
    
    func saveTasks() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(tasks) {
            UserDefaults.standard.set(data, forKey: tasksKey)
        }
    }
    
    func loadSavedTasks() {
        if let data = UserDefaults.standard.data(forKey: tasksKey) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let saved = try? decoder.decode([Task].self, from: data) {
                // 只用保存的状态和用时覆盖初始任务
                for (i, task) in tasks.enumerated() {
                    if let match = saved.first(where: { $0.id == task.id }) {
                        tasks[i].status = match.status
                        tasks[i].actualMinutes = match.actualMinutes
                    }
                }
            }
        }
    }
    // 后续可添加保存、更新等方法
}

@main
struct StudyPlanApp: App {
    @StateObject var taskStore = TaskStore()
    @StateObject var appSettings = AppSettings()
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(taskStore)
                .environmentObject(appSettings)
        }
    }
}
