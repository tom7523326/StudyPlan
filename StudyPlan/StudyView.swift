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
            
            Text(timeString)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(isOvertime ? .red : .primary)
                .onChange(of: elapsedSeconds) { _ in
                    if isOvertime && !showOvertimeAlert {
                        showOvertimeAlert = true
                    }
                }
            
            if isOvertime {
                Text("已超时！请尽快完成任务")
                    .foregroundColor(.red)
                    .font(.headline)
            }
            
            HStack(spacing: 24) {
                Button(action: togglePause) {
                    HStack {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        Text(isPaused ? "继续" : "暂停")
                    }
                    .font(.title3)
                    .frame(width: 120, height: 44)
                    .background(Color.orange.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!timerActive)
                
                Button(action: completeTask) {
                    Text("完成任务")
                        .font(.title3)
                        .frame(width: 120, height: 44)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 16)
            
            Spacer()
        }
        .padding()
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .alert(isPresented: $showOvertimeAlert) {
            Alert(title: Text("超时提醒"), message: Text("已超过预期时间！"), dismissButton: .default(Text("知道了")))
        }
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
        // 更新任务状态和用时
        if let idx = taskStore.tasks.firstIndex(where: { $0.id == task.id }) {
            taskStore.tasks[idx].status = .completed
            taskStore.tasks[idx].actualMinutes = elapsedSeconds / 60
        }
        presentationMode.wrappedValue.dismiss()
    }
} 