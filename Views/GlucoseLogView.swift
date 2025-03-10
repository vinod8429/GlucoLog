import SwiftUI
import Charts

struct GlucoseLogView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var showingAddReading = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Today's Readings") {
                    if healthKitManager.readings.isEmpty {
                        Text("No readings for today")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(healthKitManager.readings.prefix(5)) { reading in
                            GlucoseReadingRow(reading: reading)
                                .transition(.slide)
                        }
                    }
                }
                
                Section("Today's Trend") {
                    Chart(healthKitManager.readings) { reading in
                        LineMark(
                            x: .value("Time", reading.timestamp),
                            y: .value("Glucose", reading.value)
                        )
                        .foregroundStyle(reading.status.color)
                        
                        PointMark(
                            x: .value("Time", reading.timestamp),
                            y: .value("Glucose", reading.value)
                        )
                        .foregroundStyle(reading.status.color)
                    }
                    .frame(height: 200)
                }
            }
            .navigationTitle("Glucose Log")
            .toolbar {
                Button(action: { showingAddReading = true }) {
                    Image(systemName: "plus")
                        .symbolEffect(.bounce, value: showingAddReading)
                }
            }
            .sheet(isPresented: $showingAddReading) {
                AddGlucoseReadingView()
            }
            .task {
                await healthKitManager.fetchTodaysReadings()
            }
            .refreshable {
                await healthKitManager.fetchTodaysReadings()
            }
            .background(Theme.backgroundColor)
            .scrollContentBackground(.hidden)
        }
    }
}

struct GlucoseReadingRow: View {
    let reading: GlucoseReading
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(Int(reading.value)) mg/dL")
                    .font(.headline)
                Text(reading.type.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(reading.status.color)
                .frame(width: 12, height: 12)
            
            Text(reading.timestamp, style: .time)
                .foregroundColor(.secondary)
        }
    }
} 
