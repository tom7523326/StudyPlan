import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @State private var selectedScope: StatisticsScope = .week
    @Namespace private var animation
    
    var body: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > 700
            NavigationView {
                VStack(spacing: 20) {
                    // 成就与激励卡片
                    if isWide {
                        HStack(spacing: 24) {
                            AchievementCard(title: "累计全勤天数", value: "\(totalPerfectDays)", icon: "star.fill", color: appSettings.themeColor)
                            AchievementCard(title: "最长连续全勤", value: "\(maxStreak)", icon: "flame.fill", color: .orange)
                        }
                        .padding(.top)
                    } else {
                        VStack(spacing: 16) {
                            AchievementCard(title: "累计全勤天数", value: "\(totalPerfectDays)", icon: "star.fill", color: appSettings.themeColor)
                            AchievementCard(title: "最长连续全勤", value: "\(maxStreak)", icon: "flame.fill", color: .orange)
                        }
                        .padding(.top)
                    }
                    Text(appSettings.motivation)
                        .font(.headline)
                        .foregroundColor(appSettings.themeColor)
                    // 统计范围切换
                    Picker("统计范围", selection: $selectedScope) {
                        ForEach(StatisticsScope.allCases, id: \.self) { scope in
                            Text(scope.title)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding([.horizontal])
                    // 日历/进度区
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(filteredDates, id: \.self) { date in
                                let tasks = taskStore.tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
                                let completed = tasks.filter { $0.status == .completed }.count
                                let total = tasks.count
                                let totalMinutes = tasks.reduce(0) { $0 + $1.actualMinutes }
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(date, style: .date)
                                            .font(.headline)
                                        ProgressView(value: total == 0 ? 0 : Double(completed) / Double(total)) {
                                            Text("完成：\(completed)/\(total)")
                                                .font(.caption)
                                        }
                                        .accentColor(appSettings.themeColor)
                                        HStack(spacing: 8) {
                                            Image(systemName: "clock")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("用时 \(totalMinutes) 分钟")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    Spacer()
                                    if completed == total && total > 0 {
                                        Label("全勤", systemImage: "star.fill")
                                            .foregroundColor(appSettings.themeColor)
                                    }
                                }
                                .padding(.horizontal)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: appSettings.themeColor.opacity(0.08), radius: 2, x: 0, y: 1)
                                .animation(.spring(), value: completed)
                            }
                        }
                        .padding(.vertical)
                    }
                    Spacer()
                }
                .navigationTitle("任务统计")
            }
        }
    }
    
    // 统计范围
    enum StatisticsScope: String, CaseIterable {
        case week, month, all
        var title: String {
            switch self {
            case .week: return "本周"
            case .month: return "本月"
            case .all: return "全部"
            }
        }
    }
    // 成就统计
    var allDates: [Date] {
        let dates = Set(taskStore.tasks.map { Calendar.current.startOfDay(for: $0.date) })
        return dates.sorted()
    }
    var perfectDays: [Date] {
        allDates.filter { date in
            let tasks = taskStore.tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            return !tasks.isEmpty && tasks.allSatisfy { $0.status == .completed }
        }
    }
    var totalPerfectDays: Int { perfectDays.count }
    var maxStreak: Int {
        var maxStreak = 0
        var currentStreak = 0
        let sorted = allDates
        for i in 0..<sorted.count {
            if perfectDays.contains(sorted[i]) {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        return maxStreak
    }
    // 按范围过滤日期
    var filteredDates: [Date] {
        let now = Date()
        let calendar = Calendar.current
        switch selectedScope {
        case .week:
            // 本周一
            let weekday = calendar.component(.weekday, from: now)
            let daysFromMonday = (weekday + 5) % 7 // 周日=1, 周一=2
            guard let weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: now)) else { return allDates }
            return allDates.filter { $0 >= weekStart && $0 <= now }
        case .month:
            // 本月1号
            let comps = calendar.dateComponents([.year, .month], from: now)
            guard let monthStart = calendar.date(from: comps) else { return allDates }
            return allDates.filter { $0 >= monthStart && $0 <= now }
        case .all:
            return allDates
        }
    }
}

struct AchievementCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(color)
            Text(value)
                .font(.title)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 120, height: 100)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: color.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
            .environmentObject(TaskStore())
    }
} 