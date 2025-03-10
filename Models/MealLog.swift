import Foundation

struct MealLog: Identifiable {
    let id = UUID()
    let name: String
    let timestamp: Date
    let photoURL: URL?
    var tags: Set<String>
    var notes: String?
    var glucoseReadingBefore: GlucoseReading?
    var glucoseReadingAfter: GlucoseReading?
} 