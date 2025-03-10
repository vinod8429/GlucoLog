import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var showingAddReading = false
    @State private var showingAddMeal = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Latest Reading Card
                    VStack(spacing: 20) {
                        LatestReadingCard()
                    }
                    .modifier(CardStyle())
                    
                    // Today's Meals
                    VStack(alignment: .leading, spacing: 12) {
                        TodaysMealsCard()
                    }
                    .modifier(CardStyle())
                    
                    // Quick Actions
                    HStack(spacing: 12) {
                        // Add Reading Button
                        Button(action: { showingAddReading = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Add Reading")
                                        .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accentColor.opacity(0.1))
                            .foregroundColor(Theme.accentColor)
                            .cornerRadius(12)
                        }
                        
                        // Log Meal Button
                        Button(action: { showingAddMeal = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "fork.knife.circle.fill")
                                    .font(.title2)
                                Text("Log Meal")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accentColor.opacity(0.1))
                            .foregroundColor(Theme.accentColor)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    

                    
                    // Weekly Trend
                    VStack(alignment: .leading, spacing: 12) {
                        WeeklyTrendCard()
                    }
                    .modifier(CardStyle())
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("GlucoLog")
            .task {
                if healthKitManager.readings.isEmpty {
                    healthKitManager.addSampleData()
                }
                await healthKitManager.fetchTodaysReadings()
            }
            .refreshable {
                await healthKitManager.fetchTodaysReadings()
            }
            .tint(Theme.accentColor)
            .sheet(isPresented: $showingAddReading) {
                AddGlucoseReadingView()
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView()
            }
        }
    }
}

struct LatestReadingCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest Reading")
                .font(.title2)
                .bold()
            
            HStack {
                Text(healthKitManager.latestReading?.value.formatted() ?? "---")
                    .font(.system(size: 48, weight: .bold))
                Text("mg/dL")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let status = healthKitManager.latestReading?.status {
                    Image(systemName: status == .normal ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(status.color)
                        .font(.title)
                }
            }
            
            if let timestamp = healthKitManager.latestReading?.timestamp {
                Text(timestamp, style: .relative)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct QuickActionButtons: View {
    @State private var showingAddReading = false
    @State private var showingAddMeal = false
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: { showingAddReading = true }) {
                VStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                    Text("Add Reading")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(12)
            }
            
            Button(action: { showingAddMeal = true }) {
                VStack {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.title)
                    Text("Log Meal")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showingAddReading) {
            AddGlucoseReadingView()
        }
        .sheet(isPresented: $showingAddMeal) {
            AddMealView()
        }
    }
}

struct TodaysMealsCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Meals")
                .font(.title2)
                .bold()
            
            if healthKitManager.todaysMeals.isEmpty {
                HStack {
                    Spacer()
                    Text("No meals logged today")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
            } else {
                ForEach(healthKitManager.todaysMeals.prefix(3)) { meal in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(meal.name)
                                .font(.headline)
                            Text(meal.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if let reading = meal.glucoseReadingAfter {
                            Text("\(Int(reading.value))")
                                .font(.headline)
                                .foregroundColor(reading.status.color)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct WeeklyTrendCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Trend")
                .font(.title2)
                .bold()
            
            if healthKitManager.readings.isEmpty {
                HStack {
                    Spacer()
                    Text("No data available")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
            } else {
                Chart(healthKitManager.readings) { reading in
                    LineMark(
                        x: .value("Time", reading.timestamp),
                        y: .value("Glucose", reading.value)
                    )
                    .foregroundStyle(reading.status.color.gradient)
                    
                    PointMark(
                        x: .value("Time", reading.timestamp),
                        y: .value("Glucose", reading.value)
                    )
                    .foregroundStyle(reading.status.color)
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// Refined card style without borders
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(0)
            .frame(maxWidth: .infinity)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: Color.black.opacity(0.03),
                radius: 10,
                x: 0,
                y: 4
            )
    }
}

// Quick action button style
struct QuickActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: Color.black.opacity(0.03),
                radius: 8,
                x: 0,
                y: 2
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
} 
