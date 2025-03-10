//
//  ContentView.swift
//  cursor-GlucoLog
//
//  Created by Vinod P on 23/02/25.
//

import SwiftUI
import HealthKit
import UserNotifications

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var selectedTab = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .ignoresSafeArea()
            } else {
                TabView(selection: $selectedTab) {
                    DashboardView()
                        .tabItem {
                            Label("Dashboard", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    GlucoseLogView()
                        .tabItem {
                            Label("Glucose", systemImage: "drop.fill")
                        }
                        .tag(1)
                    
                    MealLogView()
                        .tabItem {
                            Label("Meals", systemImage: "fork.knife")
                        }
                        .tag(2)
                    
                    InsightsView()
                        .tabItem {
                            Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .tag(3)
                }
                .ignoresSafeArea()
                .environmentObject(healthKitManager)
                .task {
                    if healthKitManager.readings.isEmpty {
                        healthKitManager.addSampleData()
                    }
                    await notificationManager.requestAuthorization()
                    if notificationManager.isAuthorized {
                        let calendar = Calendar.current
                        let morning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
                        let evening = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
                        notificationManager.scheduleReminders(at: [morning, evening])
                    }
                }
            }
        }
    }
    
    private func requestNotificationPermission() async {
        do {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                scheduleReminders()
            }
        } catch {
            print("Notification permission error: \(error)")
        }
    }
    
    private func scheduleReminders() {
        let content = UNMutableNotificationContent()
        content.title = "Time to Log Glucose"
        content.body = "Don't forget to log your glucose reading"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600 * 12, repeats: true)
        let request = UNNotificationRequest(identifier: "glucoseReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

#Preview {
    ContentView()
}
