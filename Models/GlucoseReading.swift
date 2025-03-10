import Foundation
import SwiftUICore
import HealthKit

struct GlucoseReading: Identifiable {
    let id = UUID()
    let value: Double
    let timestamp: Date
    let type: ReadingType
    
    enum ReadingType: String {
        case fasting = "Fasting"
        case postMeal = "Post-Meal"
        case random = "Random"
    }
    
    var status: ReadingStatus {
        switch value {
        case 0..<70: return .low
        case 70..<100: return .normal
        case 100..<125: return .borderline
        default: return .high
        }
    }
    
    enum ReadingStatus {
        case low
        case normal
        case borderline
        case high
        
        var color: Color {
            switch self {
            case .low: return .red
            case .normal: return .green
            case .borderline: return .yellow
            case .high: return .red
            }
        }
    }
} 
