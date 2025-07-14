import SwiftUI

struct AddTaskSheet: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @Binding var showSheet: Bool
    @State private var name: String = ""
    @State private var category: TaskCategory = .chinese
    @State private var isRepeat: Bool = false
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var singleDate: Date = Date()
    @State private var expectedDuration: String = ""
    @State private var showAlert = false
    @State private var alertMsg = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任务名称")) {
                    TextField("请输入任务名称", text: $name)
                        .accessibilityLabel("任务名称输入框")
                }
                Section(header: Text("学科")) {
                    Picker("学科", selection: $category) {
                        ForEach(TaskCategory.allCases) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("学科选择")
                }
                Section(header: Text("是否每天重复")) {
                    Toggle("每天重复", isOn: $isRepeat)
                        .accessibilityLabel("重复任务开关")
                }
                if isRepeat {
                    Section(header: Text("开始日期")) {
                        DatePicker("开始", selection: $startDate, displayedComponents: .date)
                            .accessibilityLabel("开始日期选择")
                    }
                    Section(header: Text("结束日期")) {
                        DatePicker("结束", selection: $endDate, in: startDate..., displayedComponents: .date)
                            .accessibilityLabel("结束日期选择")
                    }
                } else {
                    Section(header: Text("日期")) {
                        DatePicker("日期", selection: $singleDate, displayedComponents: .date)
                            .accessibilityLabel("任务日期选择")
                    }
                }
                Section(header: Text("预期用时(分钟)")) {
                    TextField("请输入分钟数", text: $expectedDuration)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("预期用时输入框")
                }
            }
            .navigationTitle("新增任务")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { 
                        showSheet = false 
                    }
                    .accessibilityLabel("取消新增任务")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") { 
                        addTask() 
                    }
                    .disabled(!canAdd)
                    .accessibilityLabel("添加任务")
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("提示"), message: Text(alertMsg), dismissButton: .default(Text("确定")))
            }
        }
    }
    
    var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && Int(expectedDuration) ?? 0 > 0 && (isRepeat ? endDate >= startDate : true)
    }
    
    func addTask() {
        guard let minutes = Int(expectedDuration), minutes > 0 else {
            alertMsg = "请输入有效的分钟数"
            showAlert = true
            return
        }
        
        if isRepeat {
            var date = Calendar.current.startOfDay(for: startDate)
            let end = Calendar.current.startOfDay(for: endDate)
            while date <= end {
                let task = Task(
                    name: name, 
                    category: category, 
                    expectedDuration: minutes, 
                    actualDuration: 0, 
                    date: date, 
                    status: .pending
                )
                taskStore.addTask(task)
                date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
            }
        } else {
            let date = Calendar.current.startOfDay(for: singleDate)
            let task = Task(
                name: name, 
                category: category, 
                expectedDuration: minutes, 
                actualDuration: 0, 
                date: date, 
                status: .pending
            )
            taskStore.addTask(task)
        }
        
        showSheet = false
    }
} 