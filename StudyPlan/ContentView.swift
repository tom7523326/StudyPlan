//
//  ContentView.swift
//  StudyPlan
//
//  Created by 汤寿麟 on 2025/7/11.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @State private var selectedDate = Date()
    @State private var expandedTaskID: UUID? = nil
    @Namespace private var animation
    
    var body: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > 700
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部进度与激励
                    HStack(alignment: .center) {
                        if todayTasks.isEmpty {
                            VStack {
                                Image(systemName: "circle")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("0%")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 60, height: 60)
                            .padding(.trailing, 8)
                        } else {
                            VStack {
                                ProgressView(value: Double(completedCount) / Double(todayTasks.count)) {
                                    Text("今日进度")
                                        .font(.headline)
                                }
                                .progressViewStyle(CircularProgressViewStyle(tint: appSettings.themeColor))
                                .frame(width: 60, height: 60)
                                Text("\(Int(Double(completedCount) / Double(todayTasks.count) * 100))%")
                                    .font(.caption)
                                    .foregroundColor(appSettings.themeColor)
                            }
                            .padding(.trailing, 8)
                        }
                        VStack(alignment: .leading) {
                            DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                            Text("已完成 \(completedCount)/\(todayTasks.count) 个任务")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(appSettings.motivation)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding([.top, .horizontal])
                    // 任务分组卡片区
                    ForEach(TaskCategory.allCases) { category in
                        let tasks = todayTasks.filter { $0.category == category }
                        if !tasks.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(category.rawValue)
                                    .font(.title2)
                                    .bold()
                                    .padding(.leading)
                                if isWide {
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                        ForEach(tasks) { task in
                                            TaskCardV2(task: task,
                                                       expanded: expandedTaskID == task.id,
                                                       onExpand: { expandedTaskID = task.id },
                                                       onCollapse: { expandedTaskID = nil },
                                                       animation: animation,
                                                       themeColor: appSettings.themeColor)
                                                .animation(.spring(), value: expandedTaskID)
                                        }
                                    }
                                } else {
                                    ForEach(tasks) { task in
                                        TaskCardV2(task: task,
                                                   expanded: expandedTaskID == task.id,
                                                   onExpand: { expandedTaskID = task.id },
                                                   onCollapse: { expandedTaskID = nil },
                                                   animation: animation,
                                                   themeColor: appSettings.themeColor)
                                            .animation(.spring(), value: expandedTaskID)
                                    }
                                }
                            }
                        }
                    }
                    Spacer(minLength: 40)
                }
            }
        }
    }
    
    // 今日任务
    var todayTasks: [Task] {
        taskStore.tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    // 今日已完成
    var completedCount: Int {
        todayTasks.filter { $0.status == .completed }.count
    }
}

struct TaskCardV2: View {
    @EnvironmentObject var taskStore: TaskStore
    var task: Task
    var expanded: Bool
    var onExpand: () -> Void
    var onCollapse: () -> Void
    var animation: Namespace.ID
    var themeColor: Color
    @State private var elapsedSeconds: Int = 0
    @State private var timerActive = false
    @State private var isPaused = false
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text("预期\(task.expectedMinutes)分钟")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                StatusBadge(status: task.status, themeColor: themeColor)
                if !expanded && task.status != .completed {
                    Button(action: {
                        onExpand()
                        if !timerActive { startTimer() }
                    }) {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeColor)
                    }
                }
                if expanded {
                    Button(action: {
                        onCollapse()
                        stopTimer()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
            if expanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text(timeString)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(isOvertime ? .red : .primary)
                        .transition(.scale.combined(with: .opacity))
                    if isOvertime {
                        Text("已超时！请尽快完成任务")
                            .foregroundColor(.red)
                            .font(.caption)
                            .transition(.opacity)
                    }
                    HStack(spacing: 24) {
                        Button(action: togglePause) {
                            HStack {
                                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                Text(isPaused ? "继续" : "暂停")
                            }
                            .font(.body)
                            .frame(width: 80, height: 36)
                            .background(Color.orange.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(!timerActive)
                        .transition(.scale)
                        Button(action: completeTask) {
                            Text("完成")
                                .font(.body)
                                .frame(width: 80, height: 36)
                                .background(themeColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .transition(.scale)
                    }
                }
                .padding(.top, 8)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color(.systemGray4).opacity(0.18), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
        .matchedGeometryEffect(id: task.id, in: animation)
        .onDisappear { stopTimer() }
    }
    
    var isOvertime: Bool {
        elapsedSeconds / 60 > task.expectedMinutes
    }
    var timeString: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    func startTimer() {
        timerActive = true
        isPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if !timerActive || isPaused { return }
            elapsedSeconds += 1
        }
    }
    func stopTimer() {
        timerActive = false
        timer?.invalidate()
        timer = nil
    }
    func togglePause() {
        isPaused.toggle()
    }
    func completeTask() {
        stopTimer()
        if let idx = taskStore.tasks.firstIndex(where: { $0.id == task.id }) {
            taskStore.tasks[idx].status = .completed
            taskStore.tasks[idx].actualMinutes = elapsedSeconds / 60
        }
        onCollapse()
    }
}

struct StatusBadge: View {
    var status: TaskStatus
    var themeColor: Color = .blue
    var body: some View {
        Text(badgeText)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    var badgeText: String {
        switch status {
        case .notStarted: return "未开始"
        case .inProgress: return "进行中"
        case .completed: return "已完成"
        }
    }
    var badgeColor: Color {
        switch status {
        case .notStarted: return themeColor
        case .inProgress: return .orange
        case .completed: return .green
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(TaskStore())
            .environmentObject(AppSettings())
    }
}
