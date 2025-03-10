import HealthKit
import PhotosUI
import SwiftUI

@MainActor
class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var latestReading: GlucoseReading?
    @Published var readings: [GlucoseReading] = []
    @Published var meals: [MealLog] = []
    @Published var todaysMeals: [MealLog] = []
    @Published var error: String?
    
    init() {
        Task {
            await requestAuthorization()
        }
    }
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run {
                self.error = "HealthKit is not available on this device"
            }
            return
        }
        
        let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
        
        do {
            try await healthStore.requestAuthorization(
                toShare: [glucoseType],
                read: [glucoseType]
            )
            
            await MainActor.run {
                self.isAuthorized = true
                Task {
                    await self.fetchTodaysReadings()
                }
            }
        } catch {
            await MainActor.run {
                self.isAuthorized = false
                self.error = error.localizedDescription
            }
        }
    }
    
    func saveReading(_ reading: GlucoseReading) async {
        guard isAuthorized else {
            await MainActor.run {
                self.error = "Not authorized to access HealthKit"
            }
            return
        }
        
        do {
            let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
            let quantity = HKQuantity(unit: .init(from: "mg/dL"), doubleValue: reading.value)
            let sample = HKQuantitySample(
                type: glucoseType,
                quantity: quantity,
                start: reading.timestamp,
                end: reading.timestamp
            )
            
            try await healthStore.save(sample)
            
            await MainActor.run {
                self.readings.insert(reading, at: 0)
                self.latestReading = reading
                self.objectWillChange.send()
            }
            
            // Fetch updated readings
            await fetchTodaysReadings()
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    func fetchTodaysReadings() async {
        guard isAuthorized else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
        
        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
                let query = HKSampleQuery(
                    sampleType: glucoseType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
                    }
                }
                healthStore.execute(query)
            }
            
            await MainActor.run {
                self.readings = samples.map { sample in
                    GlucoseReading(
                        value: sample.quantity.doubleValue(for: .init(from: "mg/dL")),
                        timestamp: sample.startDate,
                        type: .random
                    )
                }
                self.latestReading = self.readings.first
                self.objectWillChange.send()
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    func fetchTodaysMeals() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Filter meals for today
        todaysMeals = meals.filter { meal in
            meal.timestamp >= startOfDay && meal.timestamp < endOfDay
        }
    }
    
    func saveMeal(_ meal: MealLog, image: PhotosPickerItem?) {
        Task {
            if let image = image {
                if let data = try? await image.loadTransferable(type: Data.self) {
                    // Save image to documents directory
                    let fileName = UUID().uuidString + ".jpg"
                    let fileURL = FileManager.default.documentsDirectory.appendingPathComponent(fileName)
                    try? data.write(to: fileURL)
                    
                    // Create meal with image URL
                    let mealWithImage = MealLog(
                        name: meal.name,
                        timestamp: meal.timestamp,
                        photoURL: fileURL,
                        tags: meal.tags,
                        notes: meal.notes
                    )
                    
                    DispatchQueue.main.async {
                        self.meals.append(mealWithImage)
                        self.updateTodaysMeals()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.meals.append(meal)
                    self.updateTodaysMeals()
                }
            }
        }
    }
    
    func updateTodaysMeals() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        todaysMeals = meals.filter { meal in
            meal.timestamp >= startOfDay && meal.timestamp < endOfDay
        }
    }
    
    // Add sample data method
    func addSampleData() {
        // Existing glucose readings sample data
        let readings: [GlucoseReading] = [
            GlucoseReading(value: 95, timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!, type: .fasting),
            GlucoseReading(value: 140, timestamp: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!, type: .postMeal),
            GlucoseReading(value: 120, timestamp: Calendar.current.date(byAdding: .hour, value: -5, to: Date())!, type: .random),
            GlucoseReading(value: 110, timestamp: Calendar.current.date(byAdding: .hour, value: -7, to: Date())!, type: .fasting),
            GlucoseReading(value: 130, timestamp: Calendar.current.date(byAdding: .hour, value: -9, to: Date())!, type: .postMeal)
        ]
        
        // Add sample meals
        let sampleMeals: [MealLog] = [
            MealLog(
                name: "Breakfast - Oatmeal",
                timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
                photoURL: nil,
                tags: ["Low Carb", "High Protein"],
                notes: "Added berries and nuts"
            ),
            MealLog(
                name: "Lunch - Grilled Chicken Salad",
                timestamp: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!,
                photoURL: nil,
                tags: ["High Protein", "Low Carb"],
                notes: "With olive oil dressing"
            )
        ]
        
        Task {
            for reading in readings {
                await saveReading(reading)
            }
            
            // Add sample meals
            await MainActor.run {
                self.meals.append(contentsOf: sampleMeals)
                self.todaysMeals = sampleMeals
            }
        }
    }
}

// Extension for FileManager
extension FileManager {
    var documentsDirectory: URL {
        let paths = urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
} 
