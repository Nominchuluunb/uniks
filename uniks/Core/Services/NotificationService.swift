//
//  NotificationService.swift
//  uniks
//
//  Manages local notification scheduling for recurring templates.
//  No remote notifications, no telemetry — fully local.
//

import Foundation
import UserNotifications
import SwiftData

/// Manages local notification permissions and scheduling for recurring templates.
actor NotificationService {
    private let container: ModelContainer
    private let notificationCenter = UNUserNotificationCenter.current()

    init(container: ModelContainer) {
        self.container = container
    }

    /// Requests notification authorization.
    /// - Returns: Whether permission was granted.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Checks current authorization status.
    func isAuthorized() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    /// Schedules a notification for a recurring template.
    /// - Parameter template: A `Sendable` snapshot of the template to schedule notifications for.
    func schedule(template: RecurringTemplateSnapshot) async {
        guard template.isActive && template.notificationEnabled else {
            await removeNotification(for: template.id)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Time to log"
        content.body = "\(template.emoji) \(template.phrase)"
        content.sound = .default
        content.categoryIdentifier = "QUICK_LOG"
        content.userInfo = ["templateID": template.id.uuidString, "phrase": template.phrase]

        let trigger: UNNotificationTrigger

        switch template.frequency {
        case .hourly:
            // Every 2 hours during waking hours
            var dateComponents = DateComponents()
            dateComponents.minute = template.minute
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        case .daily:
            var dateComponents = DateComponents()
            dateComponents.hour = template.hour
            dateComponents.minute = template.minute
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        case .weekly:
            var dateComponents = DateComponents()
            dateComponents.hour = template.hour
            dateComponents.minute = template.minute
            dateComponents.weekday = 2 // Monday
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        }

        let request = UNNotificationRequest(
            identifier: notificationID(for: template.id),
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    /// Removes a scheduled notification for a template.
    func removeNotification(for templateID: UUID) async {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [notificationID(for: templateID)]
        )
    }

    /// Reschedules all active templates. Call on app launch.
    func rescheduleAll() async {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<RecurringTemplate>(
            predicate: #Predicate { $0.isActive == true }
        )
        guard let templates = try? context.fetch(descriptor) else { return }

        // Remove all existing Uniks notifications
        notificationCenter.removeAllPendingNotificationRequests()

        for template in templates where template.notificationEnabled {
            await schedule(template: template.snapshot)
        }
    }

    /// Registers notification categories and actions.
    func registerCategories() async {
        let logAction = UNNotificationAction(
            identifier: "LOG_NOW",
            title: "Log Now",
            options: [.foreground]
        )

        let category = UNNotificationCategory(
            identifier: "QUICK_LOG",
            actions: [logAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([category])
    }

    // MARK: - Private

    private func notificationID(for templateID: UUID) -> String {
        "uniks.recurring.\(templateID.uuidString)"
    }
}
