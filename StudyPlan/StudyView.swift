import SwiftUI

struct StudyView: View {
    @EnvironmentObject var taskStore: TaskStore
    @Environment(\.presentationMode) var presentationMode
    let task: Task
    @State private var elapsedSeconds: Int = 0
    @State private var timerActive = false
    @State private var showOvertimeAlert = false
    @State private var completed = false
    @State private var isPaused = false
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 32) {
            Text(task.name)
                .font(.largeTitle)
                .padding(.top, 40)
                .accessibilityLabel("当前任务：\(task.name)")
            
            Text(timeString)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(isOvertime ? .red : .primary)
                .onChange(of: elapsedSeconds) { _ in
                    if isOvertime && !showOvertimeAlert {
                        showOvertimeAlert = true
                    }
                }
                .accessibilityLabel("已用时间：\(timeString)")
            
            if isOvertime {
                Text("已超时！请尽快完成任务")
                    .foregroundColor(.red)
                    .font(.headline)
                    .accessibilityLabel("任务已超时提醒")
            }
            
            HStack(spacing: 24) {
                Button(action: togglePause) {
                    HStack {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        Text(isPaused ? "继续" : "暂停")
                    }
                    .font(.title2)
                    .frame(width: 120, height: 50)
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
                    .font(.title2)
                    .frame(width: 120, height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .accessibilityLabel("完成任务")
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .navigationTitle("学习中")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .alert("任务超时", isPresented: $showOvertimeAlert) {
            Button("继续") { showOvertimeAlert = false }
            Button("完成") { completeTask() }
        } message: {
            Text("任务已超过预期时间，是否继续？")
        }
    }
    
    var isOvertime: Bool {
        elapsedSeconds / 60 > task.expectedDuration
    }
    
    var timeString: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func startTimer() {
        timerActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if !isPaused {
                elapsedSeconds += 1
            }
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
        // 更新任务状态和用时
        var updatedTask = task
        updatedTask.status = .completed
        updatedTask.actualDuration = elapsedSeconds / 60
        updatedTask.endTime = Date()
        taskStore.updateTask(updatedTask)
        
        presentationMode.wrappedValue.dismiss()
    }
} 