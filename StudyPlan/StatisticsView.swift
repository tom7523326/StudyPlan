import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @State private var scope: StatisticsScope = .all
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // 概览统计卡片
                    OverviewStatsCard()
                    
                    // 学科用时分布卡片
                    SubjectDistributionCard()
                    
                    // 时间趋势卡片
                    TimeTrendCard()
                    
                    // 每日进度卡片
                    DailyProgressCard()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .navigationTitle("任务统计")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - 概览统计卡片
    @ViewBuilder
    private func OverviewStatsCard() -> some View {
        StatisticsSectionCard(
            title: "学习概览",
            icon: "chart.bar.fill",
            iconColor: .blue
        ) {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    StatItemView(
                        title: "总学习时长",
                        value: "\(totalStudyMinutes)",
                        unit: "分钟",
                        icon: "clock.fill",
                        color: .blue
                    )
                    
                    StatItemView(
                        title: "完成任务",
                        value: "\(completedTasks)",
                        unit: "个",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                }
                
                HStack(spacing: 16) {
                    StatItemView(
                        title: "学习天数",
                        value: "\(totalStudyDays)",
                        unit: "天",
                        icon: "calendar.badge.checkmark",
                        color: .orange
                    )
                    
                    StatItemView(
                        title: "连续天数",
                        value: "\(maxStreak)",
                        unit: "天",
                        icon: "flame.fill",
                        color: .red
                    )
                }
            }
        }
    }
    
    // MARK: - 学科分布卡片
    @ViewBuilder
    private func SubjectDistributionCard() -> some View {
        StatisticsSectionCard(
            title: "学科用时分布",
            icon: "chart.pie.fill",
            iconColor: .purple
        ) {
            VStack(spacing: 16) {
                if totalStudyMinutes == 0 {
                    EmptyStateView(
                        icon: "chart.pie",
                        title: "暂无学习数据",
                        subtitle: "开始学习后这里将显示各学科用时分布"
                    )
                } else {
                    // 饼图
                    SubjectPieChartView(subjectMinutes: subjectMinutes)
                        .frame(height: 200)
                    
                    // 学科列表
                    VStack(spacing: 8) {
                        ForEach(subjectMinutes, id: \.0) { subject, minutes, color in
                            SubjectProgressRow(
                                subject: subject,
                                minutes: minutes,
                                percentage: Double(minutes) / Double(max(totalStudyMinutes, 1)),
                                color: color
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 时间趋势卡片
    @ViewBuilder
    private func TimeTrendCard() -> some View {
        StatisticsSectionCard(
            title: "时间范围",
            icon: "calendar",
            iconColor: .green
        ) {
            VStack(spacing: 16) {
                // 时间范围选择器
                Picker("统计范围", selection: $scope) {
                    ForEach(StatisticsScope.allCases, id: \.self) { scope in
                        Text(scope.title).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                
                // 范围统计信息
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("时间范围")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(scope.description)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("学习天数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(filteredDates.count) 天")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
    
    // MARK: - 每日进度卡片
    @ViewBuilder
    private func DailyProgressCard() -> some View {
        StatisticsSectionCard(
            title: "每日进度",
            icon: "list.bullet.clipboard",
            iconColor: .indigo
        ) {
            VStack(spacing: 12) {
                if filteredDates.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.exclamationmark",
                        title: "暂无学习记录",
                        subtitle: "在选定时间范围内没有学习记录"
                    )
                } else {
                    ForEach(filteredDates.reversed(), id: \.self) { date in
                        EnhancedDailyProgressRow(date: date)
                    }
                }
            }
        }
    }
    
    // MARK: - 统计范围枚举
    enum StatisticsScope: String, CaseIterable {
        case week, month, all
        
        var title: String {
            switch self {
            case .week: return "本周"
            case .month: return "本月"
            case .all: return "全部"
            }
        }
        
        var description: String {
            let calendar = Calendar.current
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            
            switch self {
            case .week:
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
                let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
                return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
            case .month:
                let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
                let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
                return "\(formatter.string(from: startOfMonth)) - \(formatter.string(from: endOfMonth))"
            case .all:
                return "全部时间"
            }
        }
    }
    
    // MARK: - 计算属性
    var allDates: [Date] {
        let dates = Set(taskStore.tasks.map { Calendar.current.startOfDay(for: $0.date) })
        return dates.sorted()
    }
    
    var filteredDates: [Date] {
        let calendar = Calendar.current
        let now = Date()
        switch scope {
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return allDates.filter { $0 >= startOfWeek }
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return allDates.filter { $0 >= startOfMonth }
        case .all:
            return allDates
        }
    }
    
    var totalStudyMinutes: Int {
        let tasks = taskStore.tasks.filter { filteredDates.contains(Calendar.current.startOfDay(for: $0.date)) }
        return tasks.reduce(0) { $0 + $1.actualDuration }
    }
    
    var completedTasks: Int {
        let tasks = taskStore.tasks.filter { filteredDates.contains(Calendar.current.startOfDay(for: $0.date)) }
        return tasks.filter { $0.status == .completed }.count
    }
    
    var totalStudyDays: Int {
        return filteredDates.count
    }
    
    var maxStreak: Int {
        var maxStreak = 0
        var currentStreak = 0
        let perfectDays = filteredDates.filter { date in
            let tasks = taskStore.tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            return !tasks.isEmpty && tasks.allSatisfy { $0.status == .completed }
        }
        
        for date in allDates {
            if perfectDays.contains(date) {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        return maxStreak
    }
    
    var subjectMinutes: [(String, Int, Color)] {
        let tasks = taskStore.tasks.filter { filteredDates.contains(Calendar.current.startOfDay(for: $0.date)) }
        let grouped = Dictionary(grouping: tasks, by: { $0.category })
        let colors: [TaskCategory: Color] = [
            .chinese: .blue, .math: .green, .english: .orange, .piano: .purple
        ]
        return grouped.map { (cat, arr) in
            (cat.rawValue, arr.reduce(0) { $0 + $1.actualDuration }, colors[cat] ?? .gray)
        }.sorted { $0.1 > $1.1 }
    }
}

// MARK: - 自定义组件

struct StatisticsSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title2)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // 内容
            content
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct StatItemView: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct SubjectPieChartView: View {
    let subjectMinutes: [(String, Int, Color)]
    
    var total: Int { 
        subjectMinutes.map { $0.1 }.reduce(0, +) 
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 饼图
                ForEach(0..<subjectMinutes.count, id: \.self) { index in
                    PieSlice(
                        start: angle(for: index),
                        end: angle(for: index + 1),
                        color: subjectMinutes[index].2
                    )
                }
                
                // 中心圆
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: geometry.size.width * 0.4, height: geometry.size.height * 0.4)
                
                // 中心文字
                VStack(spacing: 4) {
                    Text("总用时")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(total)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("分钟")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func angle(for index: Int) -> Angle {
        let sum = subjectMinutes.prefix(index).map { Double($0.1) }.reduce(0, +)
        return .degrees(360 * sum / Double(max(total, 1)))
    }
}

struct PieSlice: View {
    var start: Angle
    var end: Angle
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width/2, y: geometry.size.height/2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                path.move(to: center)
                path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
            }
            .fill(color)
        }
    }
}

struct SubjectProgressRow: View {
    let subject: String
    let minutes: Int
    let percentage: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // 颜色指示器
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            // 学科名称
            Text(subject)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            // 时间和百分比
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(minutes) 分钟")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(Int(percentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EnhancedDailyProgressRow: View {
    let date: Date
    @EnvironmentObject var taskStore: TaskStore
    
    var body: some View {
        let tasks = taskStore.tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        let completed = tasks.filter { $0.status == .completed }.count
        let total = tasks.count
        let totalMinutes = tasks.reduce(0) { $0 + $1.actualDuration }
        let progress = total == 0 ? 0.0 : Double(completed) / Double(total)
        
        HStack(spacing: 16) {
            // 日期
            VStack(alignment: .leading, spacing: 2) {
                Text(date, format: .dateTime.month(.abbreviated).day())
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(date, format: .dateTime.weekday(.wide))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60, alignment: .leading)
            
            // 进度信息
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("完成 \(completed)/\(total)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if completed == total && total > 0 {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: progress)))
                
                HStack {
                    Label("\(totalMinutes) 分钟", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func progressColor(for progress: Double) -> Color {
        if progress >= 1.0 {
            return .green
        } else if progress >= 0.7 {
            return .orange
        } else {
            return .blue
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 32)
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
            .environmentObject(TaskStore())
            .environmentObject(AppSettings())
    }
} 