import UserNotifications
import Foundation

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("通知权限已授予")
                } else if let error = error {
                    print("通知权限请求失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func scheduleTaskReminder(for task: Task, reminderTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "学习提醒"
        content.body = "该开始学习 \(task.name) 了！预计用时 \(task.expectedDuration) 分钟"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "TASK_REMINDER"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "task_reminder_\(task.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("添加通知失败: \(error.localizedDescription)")
            } else {
                print("已为任务 \(task.name) 设置提醒")
            }
        }
    }
    
    func cancelTaskReminder(for task: Task) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["task_reminder_\(task.id)"])
    }
    
    func scheduleDailyStudyReminder(at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "每日学习提醒"
        content.body = "今天的学习计划准备好了，开始你的学习之旅吧！"
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_study_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("添加每日提醒失败: \(error.localizedDescription)")
            } else {
                print("已设置每日学习提醒")
            }
        }
    }
    
    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_study_reminder"])
    }
    
    func scheduleTaskOverdueNotification(for task: Task) {
        let content = UNMutableNotificationContent()
        content.title = "任务超时提醒"
        content.body = "任务 \(task.name) 已超过预期时间，请注意时间管理"
        content.sound = .default
        content.categoryIdentifier = "TASK_OVERDUE"
        
        // 在预期时间结束后5分钟提醒
        let reminderTime = Calendar.current.date(byAdding: .minute, value: task.expectedDuration + 5, to: Date()) ?? Date()
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "task_overdue_\(task.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("添加超时通知失败: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelTaskOverdueNotification(for task: Task) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["task_overdue_\(task.id)"])
    }
    
    func setupNotificationCategories() {
        // 任务提醒类别
        let taskReminderCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [
                UNNotificationAction(identifier: "START_TASK", title: "开始学习", options: [.foreground]),
                UNNotificationAction(identifier: "SNOOZE", title: "稍后提醒", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        // 每日提醒类别
        let dailyReminderCategory = UNNotificationCategory(
            identifier: "DAILY_REMINDER",
            actions: [
                UNNotificationAction(identifier: "VIEW_TASKS", title: "查看任务", options: [.foreground])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        // 超时提醒类别
        let overdueCategory = UNNotificationCategory(
            identifier: "TASK_OVERDUE",
            actions: [
                UNNotificationAction(identifier: "COMPLETE_TASK", title: "完成任务", options: [.foreground]),
                UNNotificationAction(identifier: "EXTEND_TIME", title: "延长时间", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            taskReminderCategory,
            dailyReminderCategory,
            overdueCategory
        ])
    }
    
    func handleNotificationAction(_ actionIdentifier: String, for notificationRequest: UNNotificationRequest) {
        switch actionIdentifier {
        case "START_TASK":
            // 处理开始任务的逻辑
            print("用户选择开始任务")
        case "SNOOZE":
            // 处理稍后提醒的逻辑
            print("用户选择稍后提醒")
        case "VIEW_TASKS":
            // 处理查看任务的逻辑
            print("用户选择查看任务")
        case "COMPLETE_TASK":
            // 处理完成任务的逻辑
            print("用户选择完成任务")
        case "EXTEND_TIME":
            // 处理延长时间的逻辑
            print("用户选择延长时间")
        default:
            break
        }
    }
} 