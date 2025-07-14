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
                    expectedDuration: tpl.2,
                    actualDuration: 0,
                    date: date,
                    status: .pending
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
                        tasks[i].actualDuration = match.actualDuration
                        tasks[i].startTime = match.startTime
                        tasks[i].endTime = match.endTime
                    }
                }
            }
        }
    }
    
    // 更新任务
    func updateTask(_ updatedTask: Task) {
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            tasks[index] = updatedTask
        }
    }
    
    // 删除任务
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
    }
    
    // 添加新任务
    func addTask(_ task: Task) {
        tasks.append(task)
    }
    
    // 导入任务
    func importTasks(_ importedTasks: [Task]) {
        // 合并导入的任务，避免重复
        for importedTask in importedTasks {
            if !tasks.contains(where: { $0.id == importedTask.id }) {
                tasks.append(importedTask)
            } else {
                // 如果任务已存在，更新它
                updateTask(importedTask)
            }
        }
    }
    
    // 清除所有任务
    func clearAllTasks() {
        tasks.removeAll()
    }
    
    // 获取指定日期的任务
    func tasks(for date: Date) -> [Task] {
        return tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    // 获取已完成的任务
    func completedTasks() -> [Task] {
        return tasks.filter { $0.status == .completed }
    }
    
    // 获取进行中的任务
    func inProgressTasks() -> [Task] {
        return tasks.filter { $0.status == .inProgress }
    }
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
                .onAppear {
                    // 设置通知
                    NotificationManager.shared.requestPermission()
                    NotificationManager.shared.setupNotificationCategories()
                }
        }
    }
}
