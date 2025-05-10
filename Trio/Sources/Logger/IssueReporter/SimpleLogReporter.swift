import Foundation
import SwiftDate

final class SimpleLogReporter: IssueReporter {
    private let fileManager = FileManager.default

    // Constants for maintenance
    private static let logRetentionDays = 4
    private static let zipRetentionCount = 3

    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }

    // MARK: - Date and Name Utilities

    // Utility methods for generating log names - centralized logic
    static func currentLogName() -> String {
        let now = Date()
        return Formatter.logdateFormatter.string(from: now)
    }

    static func logNameForDate(daysAgo: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return Formatter.logdateFormatter.string(from: date)
    }

    static func previousLogName() -> String {
        logNameForDate(daysAgo: 1)
    }

    static func getAllLogNames() -> [String] {
        var names = [currentLogName()]
        // Get names for the past retention period (default: 4 days)
        for i in 1 ..< logRetentionDays {
            names.append(logNameForDate(daysAgo: i))
        }
        return names
    }

    static func currentDate() -> Date {
        Date()
    }

    static func startOfCurrentDay() -> Date {
        let now = Date()
        return Calendar.current.startOfDay(for: now)
    }

    // MARK: - IssueReporter Implementation

    func setup() {}

    func setUserIdentifier(_: String?) {}

    func reportNonFatalIssue(withName _: String, attributes _: [String: String]) {}

    func reportNonFatalIssue(withError _: NSError) {}

    func log(_ category: String, _ message: String, file: String, function: String, line: UInt) {
        let now = SimpleLogReporter.currentDate()
        let startOfDay = SimpleLogReporter.startOfCurrentDay()
        let logName = SimpleLogReporter.currentLogName()
        let prevLogName = SimpleLogReporter.previousLogName()

        if !fileManager.fileExists(atPath: SimpleLogReporter.logDir) {
            try? fileManager.createDirectory(
                atPath: SimpleLogReporter.logDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        if !fileManager.fileExists(atPath: SimpleLogReporter.logFile(name: logName)) {
            createFile(at: startOfDay)
            try? fileManager.removeItem(atPath: SimpleLogReporter.logFilePrev(name: prevLogName))
            debug(.service, "Removing log file from 2 days ago: \(SimpleLogReporter.logFilePrev(name: prevLogName))")
        }

        let logEntry = "\(dateFormatter.string(from: now)) [\(category)] \(file.file) - \(function) - \(line) - \(message)\n"
        let data = logEntry.data(using: .utf8)!
        try? data.append(fileURL: URL(fileURLWithPath: SimpleLogReporter.logFile(name: logName)))
    }

    private func createFile(at date: Date) {
        let logName = SimpleLogReporter.currentLogName()
        fileManager.createFile(atPath: SimpleLogReporter.logFile(name: logName), contents: nil, attributes: [.creationDate: date])
    }

    // MARK: - File Path Utilities

    static func logFile(name: String) -> String {
        let fullpath = getDocumentsDirectory().appendingPathComponent("logs/\(name).log").path
        return fullpath
    }

    static var logDir: String {
        getDocumentsDirectory().appendingPathComponent("logs").path
    }

    static func logFilePrev(name: String) -> String {
        let fullpath = getDocumentsDirectory().appendingPathComponent("logs/\(name).log").path
        return fullpath
    }

    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    // MARK: - Watch Log Functions

    static func watchLogFile(name: String) -> String {
        getDocumentsDirectory().appendingPathComponent("logs/watch_\(name).log").path
    }

    static func watchLogFilePrev(name: String) -> String {
        getDocumentsDirectory().appendingPathComponent("logs/watch_\(name).log").path
    }

    static func appendToWatchLog(_ logContent: String) {
        let startOfDay = startOfCurrentDay()
        let logName = currentLogName()
        let prevLogName = previousLogName()

        let fileManager = FileManager.default
        let logDir = getDocumentsDirectory().appendingPathComponent("logs")
        let logFile = URL(fileURLWithPath: watchLogFile(name: logName))
        let prevLogFile = URL(fileURLWithPath: watchLogFilePrev(name: prevLogName))

        // Create logs directory if needed
        if !fileManager.fileExists(atPath: logDir.path) {
            try? fileManager.createDirectory(at: logDir, withIntermediateDirectories: true)
        }

        // Rotate if needed
        if fileManager.fileExists(atPath: logFile.path),
           let attributes = try? fileManager.attributesOfItem(atPath: logFile.path),
           let creationDate = attributes[.creationDate] as? Date,
           creationDate < startOfDay
        {
            try? fileManager.removeItem(at: prevLogFile)
            try? fileManager.moveItem(at: logFile, to: prevLogFile)
            fileManager.createFile(atPath: logFile.path, contents: nil, attributes: [.creationDate: startOfDay])
        }

        if let data = (logContent + "\n").data(using: .utf8) {
            try? data.append(fileURL: logFile)
        }
    }

    // MARK: - Cleanup Functions

    // Cleanup log files to match retention period
    static func cleanupLogDirectory(retentionDays: Int = logRetentionDays) {
        let fileManager = FileManager.default

        // Get the log directory path
        let logDirPath = logDir

        // Ensure the directory exists
        guard fileManager.fileExists(atPath: logDirPath) else {
            return
        }

        do {
            // Get all files in the logs directory
            let logDirURL = URL(fileURLWithPath: logDirPath)
            let contents = try fileManager.contentsOfDirectory(
                at: logDirURL,
                includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )

            // Calculate the cutoff date
            let calendar = Calendar.current
            let now = Date()
            guard let cutoffDate = calendar.date(byAdding: .day, value: -retentionDays, to: now) else {
                return
            }

            // Set up date formatter to parse log filenames
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            debug(.service, "Cleaning up log files older than \(dateFormatter.string(from: cutoffDate))")

            var removedCount = 0
            for fileURL in contents {
                // Only process log files
                guard fileURL.pathExtension == "log" else {
                    continue
                }

                // Try to get the date from the filename first
                let filename = fileURL.deletingPathExtension().lastPathComponent
                var fileDate: Date?

                // Handle different log filename patterns
                if filename.hasPrefix("watch_") {
                    // For watch logs, extract the date part after "watch_"
                    let dateStart = filename.index(filename.startIndex, offsetBy: 6)
                    let dateSubstring = String(filename[dateStart...])
                    fileDate = dateFormatter.date(from: dateSubstring)
                } else {
                    // Regular logs - try to parse the whole filename as a date
                    fileDate = dateFormatter.date(from: filename)
                }

                // If we couldn't parse the date from the filename, fall back to file attributes
                if fileDate == nil {
                    do {
                        let attributes = try fileURL.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey])
                        // Prefer modification date, fall back to creation date
                        fileDate = attributes.contentModificationDate ?? attributes.creationDate
                    } catch {
                        // If we can't get attributes, skip this file
                        continue
                    }
                }

                // If we have a date and it's before the cutoff, delete the file
                if let date = fileDate, date < cutoffDate {
                    do {
                        try fileManager.removeItem(at: fileURL)
                        removedCount += 1
                    } catch {
                        debug(
                            .service,
                            "Failed to remove old log file \(fileURL.lastPathComponent): \(error.localizedDescription)"
                        )
                    }
                }
            }

            if removedCount > 0 {
                debug(.service, "Removed \(removedCount) log files older than the \(retentionDays)-day retention period")
            }

        } catch {
            // Log the error but don't throw - this is a maintenance function
            debug(.service, "Error cleaning up log directory: \(error.localizedDescription)")
        }
    }

    // Clean up zip exports to keep only the most recent ones
    static func cleanupZipExports(maxToKeep: Int = zipRetentionCount) {
        let fileManager = FileManager.default

        // Get the Documents directory
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        // Path to the LogExports directory
        let exportsDirectoryURL = documentsDirectory.appendingPathComponent("LogExports", isDirectory: true)

        // Check if directory exists
        guard fileManager.fileExists(atPath: exportsDirectoryURL.path) else {
            return
        }

        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: exportsDirectoryURL,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )

            // Filter and sort zip files by creation date
            let zipFiles = fileURLs.filter { $0.pathExtension == "zip" }
            let sortedFiles = try zipFiles.sorted {
                let date1 = try $0.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let date2 = try $1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return date1 > date2
            }

            // Keep only the most recent files
            if sortedFiles.count > maxToKeep {
                var removedCount = 0
                for fileURL in sortedFiles.suffix(from: maxToKeep) {
                    do {
                        try fileManager.removeItem(at: fileURL)
                        removedCount += 1
                    } catch {
                        debug(
                            .service,
                            "Failed to remove old zip file \(fileURL.lastPathComponent): \(error.localizedDescription)"
                        )
                    }
                }

                if removedCount > 0 {
                    debug(.service, "Removed \(removedCount) old zip files, keeping the \(maxToKeep) most recent")
                }
            }
        } catch {
            debug(.service, "Error cleaning up zip exports: \(error.localizedDescription)")
        }
    }

    // MARK: - Async Cleanup Methods

    // Asynchronous version of cleanupLogDirectory
    static func cleanupLogDirectoryAsync() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                cleanupLogDirectory()
                continuation.resume()
            }
        }
    }

    // Asynchronous version of cleanupZipExports
    static func cleanupZipExportsAsync() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                cleanupZipExports()
                continuation.resume()
            }
        }
    }

    // Combined async cleanup method
    static func cleanupAllLogsAsync() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                cleanupLogDirectory()
                cleanupZipExports()
                continuation.resume()
            }
        }
    }
}

private extension Data {
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: fileURL, options: .atomic)
        }
    }
}

private extension String {
    var file: String { components(separatedBy: "/").last ?? "" }
}
