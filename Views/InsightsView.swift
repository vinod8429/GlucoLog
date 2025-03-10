import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        NavigationView {
            List {
                // Average Glucose Section
                Section("Average Glucose") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("7-Day Average")
                                .font(.headline)
                            Text(String(format: "%.1f mg/dL", calculateAverageGlucose(days: 7)))
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("30-Day Average")
                                .font(.headline)
                            Text(calculateAverageGlucose(days: 30).formatted() + " mg/dL")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Time in Range Section
                Section("Time in Range (Last 7 Days)") {
                    Chart {
                        SectorMark(
                            angle: .value("Normal", calculateTimeInRange().normal),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(.green)
                        
                        SectorMark(
                            angle: .value("High", calculateTimeInRange().high),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(.red)
                        
                        SectorMark(
                            angle: .value("Low", calculateTimeInRange().low),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(.orange)
                    }
                    .frame(height: 200)
                    
                    // Legend
                    HStack(spacing: 20) {
                        Label("Normal (70-140)", systemImage: "circle.fill")
                            .foregroundColor(.green)
                        Label("High (>140)", systemImage: "circle.fill")
                            .foregroundColor(.red)
                        Label("Low (<70)", systemImage: "circle.fill")
                            .foregroundColor(.orange)
                    }
                    .font(.caption)
                }
                
                // Daily Pattern Section
                Section("Daily Pattern") {
                    Chart(healthKitManager.readings) { reading in
                        PointMark(
                            x: .value("Hour", Calendar.current.component(.hour, from: reading.timestamp)),
                            y: .value("Glucose", reading.value)
                        )
                        .foregroundStyle(reading.status.color)
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: 3)) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                Text("\(value.as(Int.self) ?? 0)")
                                    + Text("h")
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                Text("\(value.as(Int.self) ?? 0)")
                            }
                        }
                    }
                }
            }
            .background(Theme.backgroundColor)
            .scrollContentBackground(.hidden)
            .navigationTitle("Insights")
            .task {
                await healthKitManager.fetchTodaysReadings()
            }
            .refreshable {
                await healthKitManager.fetchTodaysReadings()
            }
        }
    }
    
    private func calculateAverageGlucose(days: Int) -> Double {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let relevantReadings = healthKitManager.readings.filter { reading in
            reading.timestamp >= startDate
        }
        
        guard !relevantReadings.isEmpty else { return 0 }
        let average = relevantReadings.map(\.value).reduce(0, +) / Double(relevantReadings.count)
        return (average * 10).rounded() / 10 // Round to 1 decimal place
    }
    
    private func calculateTimeInRange() -> (normal: Double, high: Double, low: Double) {
        let readings = healthKitManager.readings
        guard !readings.isEmpty else { return (1, 0, 0) } // Default to 100% normal if no readings
        
        let total = Double(readings.count)
        let normal = Double(readings.filter { $0.status == .normal }.count)
        let high = Double(readings.filter { $0.status == .high }.count)
        let low = Double(readings.filter { $0.status == .low }.count)
        
        return (
            normal: normal / total * 100,
            high: high / total * 100,
            low: low / total * 100
        )
    }
}

#Preview {
    InsightsView()
        .environmentObject(HealthKitManager())
} 
