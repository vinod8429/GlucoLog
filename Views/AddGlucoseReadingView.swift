import SwiftUI

struct AddGlucoseReadingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    @State private var glucoseValue: String = ""
    @State private var selectedType: GlucoseReading.ReadingType = .random
    @State private var date = Date()
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Reading Details") {
                    TextField("Glucose Value", text: $glucoseValue)
                        .keyboardType(.numberPad)
                    
                    Picker("Reading Type", selection: $selectedType) {
                        Text("Fasting").tag(GlucoseReading.ReadingType.fasting)
                        Text("Post Meal").tag(GlucoseReading.ReadingType.postMeal)
                        Text("Random").tag(GlucoseReading.ReadingType.random)
                    }
                    
                    DatePicker("Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Add Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReading()
                    }
                    .disabled(glucoseValue.isEmpty || isSaving)
                }
            }
            .alert("Error", isPresented: .constant(healthKitManager.error != nil)) {
                Button("OK") {
                    healthKitManager.error = nil
                }
            } message: {
                Text(healthKitManager.error ?? "")
            }
        }
    }
    
    private func saveReading() {
        guard let value = Double(glucoseValue) else { return }
        let reading = GlucoseReading(value: value, timestamp: date, type: selectedType)
        
        isSaving = true
        Task {
            await healthKitManager.saveReading(reading)
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
} 