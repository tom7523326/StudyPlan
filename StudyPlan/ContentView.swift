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
    @State private var showAddTaskSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // 顶部日期和进度卡片
                    HeaderCard()
                    
                    // 今日任务概览卡片
                    TodayOverviewCard()
                    
                    // 任务列表
                    TaskListSection()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showAddTaskSheet) {
            AddTaskSheet(showSheet: $showAddTaskSheet)
                .environmentObject(taskStore)
                .environmentObject(appSettings)
        }
    }
    
    // MARK: - 顶部日期和进度卡片
    @ViewBuilder
    private func HeaderCard() -> some View {
        VStack(spacing: 16) {
            // 日期选择和新增按钮
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDate, style: .date)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(dayOfWeek(for: selectedDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    
                    Button(action: { showAddTaskSheet = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(appSettings.themeColor)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("新增任务")
                }
            }
            
            // 进度环和统计
            HStack(spacing: 24) {
                // 进度环
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: progressPercentage)
                        .stroke(appSettings.themeColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 80, height: 80)
                        .animation(.easeInOut(duration: 0.5), value: progressPercentage)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(progressPercentage * 100))%")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("完成")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 统计信息
                VStack(alignment: .leading, spacing: 12) {
                    StatRow(
                        icon: "checkmark.circle.fill",
                        title: "已完成",
                        value: "\(completedCount)",
                        color: .green
                    )
                    
                    StatRow(
                        icon: "clock.fill",
                        title: "进行中",
                        value: "\(inProgressCount)",
                        color: .orange
                    )
                    
                    StatRow(
                        icon: "circle.fill",
                        title: "待开始",
                        value: "\(pendingCount)",
                        color: .blue
                    )
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 今日概览卡片
    @ViewBuilder
    private func TodayOverviewCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(appSettings.themeColor)
                    .font(.title2)
                
                Text("今日安排")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !todayTasks.isEmpty {
                    Text("\(todayTasks.count) 个任务")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if todayTasks.isEmpty {
                EmptyTasksView()
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Text("总预期用时")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(totalExpectedMinutes) 分钟")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    if totalActualMinutes > 0 {
                        HStack {
                            Text("实际用时")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(totalActualMinutes) 分钟")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(totalActualMinutes > totalExpectedMinutes ? .red : .green)
                        }
                    }
                    
                    // 激励语
                    if !appSettings.motivation.isEmpty {
                        HStack {
                            Image(systemName: "quote.bubble.fill")
                                .foregroundColor(appSettings.themeColor)
                                .font(.caption)
                            
                            Text(appSettings.motivation)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                            
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 任务列表区域
    @ViewBuilder
    private func TaskListSection() -> some View {
        if !todayTasks.isEmpty {
            ForEach(TaskCategory.allCases, id: \.self) { category in
                let categoryTasks = todayTasks.filter { $0.category == category }
                if !categoryTasks.isEmpty {
                    TaskCategorySection(
                        category: category,
                        tasks: categoryTasks,
                        expandedTaskID: $expandedTaskID,
                        animation: animation
                    )
                }
            }
        }
    }
    
    // MARK: - 计算属性
    var todayTasks: [Task] {
        taskStore.tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var completedCount: Int {
        todayTasks.filter { $0.status == .completed }.count
    }
    
    var inProgressCount: Int {
        todayTasks.filter { $0.status == .inProgress }.count
    }
    
    var pendingCount: Int {
        todayTasks.filter { $0.status == .pending }.count
    }
    
    var progressPercentage: Double {
        guard !todayTasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(todayTasks.count)
    }
    
    var totalExpectedMinutes: Int {
        todayTasks.reduce(0) { $0 + $1.expectedDuration }
    }
    
    var totalActualMinutes: Int {
        todayTasks.reduce(0) { $0 + $1.actualDuration }
    }
    
    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 辅助组件

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
                .frame(width: 16)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                Text("今天还没有安排任务")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("点击右上角的 + 按钮添加新任务")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 24)
    }
}

struct TaskCategorySection: View {
    let category: TaskCategory
    let tasks: [Task]
    @Binding var expandedTaskID: UUID?
    let animation: Namespace.ID
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 分类标题
            HStack {
                Image(systemName: category.iconName)
                    .foregroundColor(category.color)
                    .font(.title3)
                
                Text(category.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(tasks.count) 个")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 任务卡片
            LazyVStack(spacing: 12) {
                ForEach(tasks) { task in
                    ModernTaskCard(
                        task: task,
                        expanded: expandedTaskID == task.id,
                        onExpand: { expandedTaskID = task.id },
                        onCollapse: { expandedTaskID = nil },
                        animation: animation
                    )
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct ModernTaskCard: View {
    let task: Task
    let expanded: Bool
    let onExpand: () -> Void
    let onCollapse: () -> Void
    let animation: Namespace.ID
    
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 主要信息行
            HStack(alignment: .top, spacing: 12) {
                // 状态指示器
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        Label("\(task.expectedDuration)分钟", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if task.actualDuration > 0 {
                            Label("\(task.actualDuration)分钟", systemImage: "timer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // 状态按钮
                Button(action: toggleTaskStatus) {
                    HStack(spacing: 4) {
                        Image(systemName: task.status.iconName)
                            .font(.caption)
                        
                        Text(task.status.displayName)
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 展开的计时区域
            if expanded {
                Divider()
                    .padding(.vertical, 4)
                
                TimerSection(task: task, themeColor: appSettings.themeColor)
                    .matchedGeometryEffect(id: "timer-\(task.id)", in: animation)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusColor.opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            withAnimation(.spring()) {
                if expanded {
                    onCollapse()
                } else {
                    onExpand()
                }
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            showEditMenu()
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTaskSheet(task: task, onSave: editTask)
        }
        .alert("删除任务", isPresented: $showingDeleteAlert) {
            Button("删除", role: .destructive) {
                deleteTask()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("确定要删除任务\"\(task.name)\"吗？此操作无法撤销。")
        }
    }
    
    private var statusColor: Color {
        switch task.status {
        case .pending:
            return .blue
        case .inProgress:
            return .orange
        case .completed:
            return .green
        case .overdue:
            return .red
        }
    }
    
    private func showEditMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "编辑任务", style: .default) { _ in
            showingEditSheet = true
        })
        
        alertController.addAction(UIAlertAction(title: "删除任务", style: .destructive) { _ in
            showingDeleteAlert = true
        })
        
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 为iPad设置弹出位置
        if let popover = alertController.popoverPresentationController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(alertController, animated: true)
        }
    }
    
    private func toggleTaskStatus() {
        var updatedTask = task
        switch task.status {
        case .pending:
            updatedTask.status = .inProgress
            updatedTask.startTime = Date()
        case .inProgress:
            updatedTask.status = .completed
            updatedTask.endTime = Date()
            if let startTime = updatedTask.startTime {
                updatedTask.actualDuration = Int(Date().timeIntervalSince(startTime) / 60)
            }
        case .completed:
            updatedTask.status = .pending
            updatedTask.startTime = nil
            updatedTask.endTime = nil
            updatedTask.actualDuration = 0
        case .overdue:
            updatedTask.status = .completed
            updatedTask.endTime = Date()
            if let startTime = updatedTask.startTime {
                updatedTask.actualDuration = Int(Date().timeIntervalSince(startTime) / 60)
            }
        }
        
        taskStore.updateTask(updatedTask)
    }
    
    private func editTask(_ updatedTask: Task) {
        taskStore.updateTask(updatedTask)
    }
    
    private func deleteTask() {
        taskStore.deleteTask(task)
        
        // 添加删除动画反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// 编辑任务的Sheet
struct EditTaskSheet: View {
    let task: Task
    let onSave: (Task) -> Void
    
    @State private var taskName: String
    @State private var selectedCategory: TaskCategory
    @State private var expectedDuration: Int
    @State private var taskDate: Date
    @State private var isRepeating: Bool = false
    @State private var repeatEndDate: Date = Date()
    
    @Environment(\.dismiss) private var dismiss
    
    init(task: Task, onSave: @escaping (Task) -> Void) {
        self.task = task
        self.onSave = onSave
        self._taskName = State(initialValue: task.name)
        self._selectedCategory = State(initialValue: task.category)
        self._expectedDuration = State(initialValue: task.expectedDuration)
        self._taskDate = State(initialValue: task.date)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("任务信息") {
                    TextField("任务名称", text: $taskName)
                        .accessibilityLabel("任务名称输入框")
                    
                    Picker("学科", selection: $selectedCategory) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .accessibilityLabel("选择学科")
                    
                    Stepper("预期用时: \(expectedDuration) 分钟", value: $expectedDuration, in: 5...300, step: 5)
                        .accessibilityLabel("预期用时设置")
                    
                    DatePicker("日期", selection: $taskDate, displayedComponents: .date)
                        .accessibilityLabel("选择任务日期")
                }
                
                Section("重复设置") {
                    Toggle("重复任务", isOn: $isRepeating)
                        .accessibilityLabel("重复任务开关")
                    
                    if isRepeating {
                        DatePicker("结束日期", selection: $repeatEndDate, in: taskDate..., displayedComponents: .date)
                            .accessibilityLabel("重复任务结束日期")
                    }
                }
            }
            .navigationTitle("编辑任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .accessibilityLabel("取消编辑")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveTask()
                    }
                    .disabled(taskName.isEmpty)
                    .accessibilityLabel("保存任务")
                }
            }
        }
    }
    
    private func saveTask() {
        let updatedTask = Task(
            id: task.id,
            name: taskName,
            category: selectedCategory,
            expectedDuration: expectedDuration,
            actualDuration: task.actualDuration,
            date: taskDate,
            status: task.status,
            startTime: task.startTime,
            endTime: task.endTime
        )
        
        onSave(updatedTask)
        dismiss()
    }
}

// Timer Section for expanded task cards
struct TimerSection: View {
    let task: Task
    let themeColor: Color
    
    @EnvironmentObject var taskStore: TaskStore
    @State private var elapsedSeconds: Int = 0
    @State private var timerActive = false
    @State private var isPaused = false
    @State private var timer: Timer? = nil
    @State private var showOvertimeBanner = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .stroke(isOvertime ? Color.red : themeColor, lineWidth: 6)
                    .opacity(0.2)
                    .frame(width: 90, height: 90)
                Circle()
                    .trim(from: 0, to: min(progress, 1))
                    .stroke(isOvertime ? Color.red : themeColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 90, height: 90)
                    .animation(.linear, value: elapsedSeconds)
                Text(timeString)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(isOvertime ? .red : .primary)
            }
            
            if isOvertime {
                Text("已超时 \(overtimeMinutes) 分钟")
                    .foregroundColor(.red)
                    .font(.headline)
                    .transition(.opacity)
            } else {
                Text("还剩 \(remainingMinutes) 分钟")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
            
            HStack(spacing: 32) {
                Button(action: togglePause) {
                    HStack {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        Text(isPaused ? "继续" : "暂停")
                    }
                    .font(.title3)
                    .frame(width: 110, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(!timerActive)
                .accessibilityLabel(isPaused ? "继续计时" : "暂停计时")
                
                Button(action: completeTask) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("完成")
                    }
                    .font(.title3)
                    .frame(width: 110, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(themeColor)
                .accessibilityLabel("完成任务")
            }
        }
        .padding(.top, 8)
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            if task.status == .inProgress {
                startTimer()
            }
        }
        .onDisappear {
            stopTimer()
        }
        .overlay(
            Group {
                if showOvertimeBanner {
                    VStack {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                            Text("任务已超时！请尽快完成")
                                .foregroundColor(.white)
                                .bold()
                        }
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                        Spacer()
                    }
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }, alignment: .top
        )
    }
    
    private var isOvertime: Bool {
        elapsedSeconds / 60 > task.expectedDuration
    }
    
    private var overtimeMinutes: Int {
        max(0, elapsedSeconds / 60 - task.expectedDuration)
    }
    
    private var remainingMinutes: Int {
        max(0, task.expectedDuration - elapsedSeconds / 60)
    }
    
    private var progress: Double {
        min(Double(elapsedSeconds) / Double(task.expectedDuration * 60), 1.0)
    }
    
    private var timeString: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private func startTimer() {
        timerActive = true
        isPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if !timerActive || isPaused { return }
            elapsedSeconds += 1
            if isOvertime && !showOvertimeBanner {
                withAnimation { showOvertimeBanner = true }
            }
        }
    }
    
    private func stopTimer() {
        timerActive = false
        timer?.invalidate()
        timer = nil
        showOvertimeBanner = false
    }
    
    private func togglePause() {
        isPaused.toggle()
    }
    
    private func completeTask() {
        stopTimer()
        var updatedTask = task
        updatedTask.status = .completed
        updatedTask.actualDuration = elapsedSeconds / 60
        updatedTask.endTime = Date()
        taskStore.updateTask(updatedTask)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(TaskStore())
            .environmentObject(AppSettings())
    }
}
