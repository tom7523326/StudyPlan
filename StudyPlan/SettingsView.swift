import SwiftUI

class AppSettings: ObservableObject {
    @Published var username: String = "小明"
    @Published var themeColor: Color = .blue
    @Published var motivation: String = "每天进步一点点！"
    @Published var isDarkMode: Bool = false
    @Published var supportLargeText: Bool = false
    @Published var highContrast: Bool = false
    @Published var voiceFeedback: Bool = false
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        username = UserDefaults.standard.string(forKey: "username") ?? "小明"
        motivation = UserDefaults.standard.string(forKey: "motivation") ?? "每天进步一点点！"
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        supportLargeText = UserDefaults.standard.bool(forKey: "supportLargeText")
        highContrast = UserDefaults.standard.bool(forKey: "highContrast")
        voiceFeedback = UserDefaults.standard.bool(forKey: "voiceFeedback")
        
        if let colorData = UserDefaults.standard.data(forKey: "themeColor"),
           let color = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor {
            themeColor = Color(color)
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(motivation, forKey: "motivation")
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        UserDefaults.standard.set(supportLargeText, forKey: "supportLargeText")
        UserDefaults.standard.set(highContrast, forKey: "highContrast")
        UserDefaults.standard.set(voiceFeedback, forKey: "voiceFeedback")
        
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(themeColor), requiringSecureCoding: false) {
            UserDefaults.standard.set(colorData, forKey: "themeColor")
        }
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
        updateAppearance()
        saveSettings()
    }
    
    private func updateAppearance() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var taskStore: TaskStore
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var dataExportManager = DataExportManager.shared
    
    @State private var notificationsEnabled = true
    @State private var dailyReminderTime = Date()
    @State private var taskReminderEnabled = true
    @State private var reminderMinutesBefore = 15
    
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var exportedFileURL: URL?
    @State private var showingClearDataAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // 个人信息卡片
                    SettingsSectionCard(
                        title: "个人信息",
                        icon: "person.circle.fill",
                        iconColor: .blue
                    ) {
                        PersonalInfoSection()
                    }
                    
                    // 通知设置卡片
                    SettingsSectionCard(
                        title: "通知提醒",
                        icon: "bell.fill",
                        iconColor: .orange
                    ) {
                        NotificationSection()
                    }
                    
                    // 无障碍设置卡片
                    SettingsSectionCard(
                        title: "无障碍",
                        icon: "accessibility",
                        iconColor: .green
                    ) {
                        AccessibilitySection()
                    }
                    
                    // 数据管理卡片
                    SettingsSectionCard(
                        title: "数据管理",
                        icon: "externaldrive.fill",
                        iconColor: .purple
                    ) {
                        DataManagementSection()
                    }
                    
                    // 关于卡片
                    SettingsSectionCard(
                        title: "关于",
                        icon: "info.circle.fill",
                        iconColor: .gray
                    ) {
                        AboutSection()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataSheet(tasks: taskStore.tasks, onExport: handleDataExport)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportDataSheet(onImport: handleDataImport)
        }
        .alert("清除所有数据", isPresented: $showingClearDataAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("此操作将删除所有学习记录，无法恢复。确定要继续吗？")
        }
        .onAppear {
            notificationManager.requestPermission()
            notificationManager.setupNotificationCategories()
        }
    }
    
    // MARK: - 个人信息部分
    @ViewBuilder
    private func PersonalInfoSection() -> some View {
        VStack(spacing: 16) {
            SettingsRow(
                icon: "person.fill",
                title: "昵称",
                iconColor: .blue
            ) {
                TextField("请输入昵称", text: $appSettings.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: appSettings.username) { _ in
                        appSettings.saveSettings()
                    }
            }
            
            Divider()
            
            SettingsRow(
                icon: "paintpalette.fill",
                title: "主题色",
                iconColor: .indigo
            ) {
                ColorPicker("", selection: $appSettings.themeColor)
                    .onChange(of: appSettings.themeColor) { _ in
                        appSettings.saveSettings()
                    }
            }
            
            Divider()
            
            SettingsRow(
                icon: "quote.bubble.fill",
                title: "激励语",
                iconColor: .pink
            ) {
                TextField("请输入激励语", text: $appSettings.motivation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: appSettings.motivation) { _ in
                        appSettings.saveSettings()
                    }
            }
        }
    }
    
    // MARK: - 通知设置部分
    @ViewBuilder
    private func NotificationSection() -> some View {
        VStack(spacing: 16) {
            SettingsToggleRow(
                icon: "bell.fill",
                title: "启用通知",
                subtitle: "接收学习提醒通知",
                iconColor: .orange,
                isOn: $notificationsEnabled
            )
            .onChange(of: notificationsEnabled) { enabled in
                if enabled {
                    notificationManager.requestPermission()
                } else {
                    notificationManager.cancelDailyReminder()
                }
            }
            
            if notificationsEnabled {
                Divider()
                
                SettingsRow(
                    icon: "clock.fill",
                    title: "每日提醒时间",
                    iconColor: .blue
                ) {
                    DatePicker("", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                        .onChange(of: dailyReminderTime) { time in
                            notificationManager.scheduleDailyStudyReminder(at: time)
                        }
                }
                
                Divider()
                
                SettingsToggleRow(
                    icon: "alarm.fill",
                    title: "任务提醒",
                    subtitle: "任务开始前提醒",
                    iconColor: .red,
                    isOn: $taskReminderEnabled
                )
                
                if taskReminderEnabled {
                    Divider()
                    
                    SettingsRow(
                        icon: "timer",
                        title: "提前提醒",
                        iconColor: .mint
                    ) {
                        Picker("", selection: $reminderMinutesBefore) {
                            Text("5 分钟").tag(5)
                            Text("10 分钟").tag(10)
                            Text("15 分钟").tag(15)
                            Text("30 分钟").tag(30)
                            Text("1 小时").tag(60)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - 无障碍设置部分
    @ViewBuilder
    private func AccessibilitySection() -> some View {
        VStack(spacing: 16) {
            SettingsToggleRow(
                icon: "moon.circle.fill",
                title: "深色模式",
                subtitle: "启用深色主题",
                iconColor: .indigo,
                isOn: $appSettings.isDarkMode
            )
            .onChange(of: appSettings.isDarkMode) { _ in
                appSettings.toggleDarkMode()
            }
            
            Divider()
            
            SettingsToggleRow(
                icon: "textformat.size",
                title: "大字体支持",
                subtitle: "增大文字显示",
                iconColor: .green,
                isOn: $appSettings.supportLargeText
            )
            .onChange(of: appSettings.supportLargeText) { _ in
                appSettings.saveSettings()
            }
            
            Divider()
            
            SettingsToggleRow(
                icon: "circle.lefthalf.filled",
                title: "高对比度",
                subtitle: "提高视觉对比度",
                iconColor: .yellow,
                isOn: $appSettings.highContrast
            )
            .onChange(of: appSettings.highContrast) { _ in
                appSettings.saveSettings()
            }
            
            Divider()
            
            SettingsToggleRow(
                icon: "speaker.wave.2.fill",
                title: "语音反馈",
                subtitle: "启用语音提示",
                iconColor: .cyan,
                isOn: $appSettings.voiceFeedback
            )
            .onChange(of: appSettings.voiceFeedback) { _ in
                appSettings.saveSettings()
            }
        }
    }
    
    // MARK: - 数据管理部分
    @ViewBuilder
    private func DataManagementSection() -> some View {
        VStack(spacing: 16) {
            SettingsActionRow(
                icon: "square.and.arrow.up.fill",
                title: "导出数据",
                subtitle: "备份学习记录",
                iconColor: .blue
            ) {
                showingExportSheet = true
            }
            
            Divider()
            
            SettingsActionRow(
                icon: "square.and.arrow.down.fill",
                title: "导入数据",
                subtitle: "恢复学习记录",
                iconColor: .green
            ) {
                showingImportSheet = true
            }
            
            Divider()
            
            SettingsActionRow(
                icon: "trash.fill",
                title: "清除所有数据",
                subtitle: "删除所有学习记录",
                iconColor: .red
            ) {
                showingClearDataAlert = true
            }
        }
    }
    
    // MARK: - 关于部分
    @ViewBuilder
    private func AboutSection() -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("学习计划")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("版本 1.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            HStack {
                Text("© 2024 学习计划应用")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }
    
    // MARK: - 数据处理方法
    private func handleDataExport(format: ExportFormat) {
        switch format {
        case .csv:
            exportedFileURL = dataExportManager.exportToCSV(tasks: taskStore.tasks)
        case .json:
            exportedFileURL = dataExportManager.exportToJSON(tasks: taskStore.tasks)
        case .report:
            exportedFileURL = dataExportManager.exportStudyReport(tasks: taskStore.tasks)
        }
        
        if let url = exportedFileURL {
            shareFile(url: url)
        }
    }
    
    private func handleDataImport(fileURL: URL) {
        if let importedTasks = dataExportManager.importFromJSON(fileURL: fileURL) {
            taskStore.importTasks(importedTasks)
        }
    }
    
    private func shareFile(url: URL) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            dataExportManager.shareFile(url: url, from: rootViewController)
        }
    }
    
    private func clearAllData() {
        taskStore.clearAllTasks()
        UserDefaults.standard.removeObject(forKey: "tasks")
        UserDefaults.standard.removeObject(forKey: "userSettings")
    }
}

// MARK: - 自定义组件

struct SettingsSectionCard<Content: View>: View {
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

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    let content: Content
    
    init(icon: String, title: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 20, height: 20)
            
            Text(title)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
            
            content
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

struct SettingsActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12, weight: .medium))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 导出/导入表单

enum ExportFormat {
    case csv
    case json
    case report
}

struct ExportDataSheet: View {
    let tasks: [Task]
    let onExport: (ExportFormat) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("选择导出格式") {
                    ExportFormatRow(
                        icon: "doc.text.fill",
                        title: "CSV 格式",
                        subtitle: "适合在Excel中打开",
                        iconColor: .blue
                    ) {
                        onExport(.csv)
                        dismiss()
                    }
                    
                    ExportFormatRow(
                        icon: "doc.plaintext.fill",
                        title: "JSON 格式",
                        subtitle: "适合程序处理",
                        iconColor: .green
                    ) {
                        onExport(.json)
                        dismiss()
                    }
                    
                    ExportFormatRow(
                        icon: "doc.richtext.fill",
                        title: "学习报告",
                        subtitle: "包含统计分析",
                        iconColor: .purple
                    ) {
                        onExport(.report)
                        dismiss()
                    }
                }
            }
            .navigationTitle("导出数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ExportFormatRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title2)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ImportDataSheet: View {
    let onImport: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingDocumentPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("导入学习数据")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("选择之前导出的JSON格式文件来导入学习数据")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                Button(action: {
                    showingDocumentPicker = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                        Text("选择文件")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("导入数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    onImport(url)
                    dismiss()
                }
            case .failure(let error):
                print("文件选择失败: \(error)")
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppSettings())
            .environmentObject(TaskStore())
    }
} 