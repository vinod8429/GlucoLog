import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    func requestAuthorization() async {
        do {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            isAuthorized = settings.authorizationStatus == .authorized
            
            if settings.authorizationStatus == .notDetermined {
                isAuthorized = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound])
            }
        } catch {
            print("Notification authorization error: \(error)")
        }
    }
    
    func scheduleReminders(at times: [Date]) {
        // Remove existing reminders
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule new reminders
        for time in times {
            let components = Calendar.current.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let content = UNMutableNotificationContent()
            content.title = "Time to Log Glucose"
            content.body = "Don't forget to check and log your glucose reading"
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: "glucoseReminder-\(components.hour ?? 0)-\(components.minute ?? 0)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
} 