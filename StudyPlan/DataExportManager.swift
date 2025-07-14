import Foundation
import UIKit

class DataExportManager: ObservableObject {
    static let shared = DataExportManager()
    
    private init() {}
    
    func exportToCSV(tasks: [Task]) -> URL? {
        let csvHeader = "日期,任务名称,学科,预期用时(分钟),实际用时(分钟),状态,开始时间,结束时间\n"
        
        let csvContent = tasks.map { task in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let date = dateFormatter.string(from: task.date)
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            let startTime = task.startTime.map { timeFormatter.string(from: $0) } ?? ""
            let endTime = task.endTime.map { timeFormatter.string(from: $0) } ?? ""
            
            return "\(date),\(task.name),\(task.category.displayName),\(task.expectedDuration),\(task.actualDuration),\(task.status.displayName),\(startTime),\(endTime)"
        }.joined(separator: "\n")
        
        let fullContent = csvHeader + csvContent
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "学习数据_\(Date().timeIntervalSince1970).csv"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try fullContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("导出CSV失败: \(error)")
            return nil
        }
    }
    
    func exportToJSON(tasks: [Task]) -> URL? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let jsonData = try encoder.encode(tasks)
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "学习数据_\(Date().timeIntervalSince1970).json"
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            try jsonData.write(to: fileURL)
            return fileURL
        } catch {
            print("导出JSON失败: \(error)")
            return nil
        }
    }
    
    func importFromJSON(fileURL: URL) -> [Task]? {
        do {
            let jsonData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let tasks = try decoder.decode([Task].self, from: jsonData)
            return tasks
        } catch {
            print("导入JSON失败: \(error)")
            return nil
        }
    }
    
    func shareFile(url: URL, from viewController: UIViewController) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // iPad适配
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityViewController, animated: true)
    }
    
    func generateStudyReport(tasks: [Task]) -> String {
        let completedTasks = tasks.filter { $0.status == .completed }
        let totalTasks = tasks.count
        let completionRate = totalTasks > 0 ? Double(completedTasks.count) / Double(totalTasks) * 100 : 0
        
        let totalExpectedTime = tasks.reduce(0) { $0 + $1.expectedDuration }
        let totalActualTime = completedTasks.reduce(0) { $0 + $1.actualDuration }
        
        let subjectStats = Dictionary(grouping: completedTasks) { $0.category }
            .mapValues { tasks in
                let totalTime = tasks.reduce(0) { $0 + $1.actualDuration }
                let avgEfficiency = tasks.isEmpty ? 0 : Double(tasks.reduce(0) { $0 + $1.actualDuration }) / Double(tasks.reduce(0) { $0 + $1.expectedDuration })
                return (count: tasks.count, totalTime: totalTime, efficiency: avgEfficiency)
            }
        
        var report = """
        学习数据报告
        ==================
        
        总体统计:
        - 总任务数: \(totalTasks)
        - 已完成任务: \(completedTasks.count)
        - 完成率: \(String(format: "%.1f", completionRate))%
        - 预期总用时: \(totalExpectedTime) 分钟
        - 实际总用时: \(totalActualTime) 分钟
        
        学科统计:
        """
        
        for (category, stats) in subjectStats {
            report += """
            
            \(category.displayName):
            - 完成任务: \(stats.count)
            - 总用时: \(stats.totalTime) 分钟
            - 效率: \(String(format: "%.1f", stats.efficiency * 100))%
            """
        }
        
        return report
    }
    
    func exportStudyReport(tasks: [Task]) -> URL? {
        let report = generateStudyReport(tasks: tasks)
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "学习报告_\(Date().timeIntervalSince1970).txt"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try report.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("导出报告失败: \(error)")
            return nil
        }
    }
} 