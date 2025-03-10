import SwiftUI
import PhotosUI

struct AddMealView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    @State private var mealName = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedTags: Set<String> = []
    @State private var notes = ""
    @State private var date = Date()
    @State private var showingImagePicker = false
    @State private var selectedImageData: UIImage?
    
    let availableTags = ["High Carb", "Low Carb", "High Protein", "Vegetarian", "Low Sugar"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Meal Details") {
                    TextField("Meal Name", text: $mealName)
                    
                    DatePicker("Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        HStack {
                            Label("Add Photo", systemImage: "photo")
                            Spacer()
                            if selectedImage != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                Section("Tags") {
                    ForEach(availableTags, id: \.self) { tag in
                        Toggle(tag, isOn: Binding(
                            get: { selectedTags.contains(tag) },
                            set: { isSelected in
                                if isSelected {
                                    selectedTags.insert(tag)
                                } else {
                                    selectedTags.remove(tag)
                                }
                            }
                        ))
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMeal()
                        dismiss()
                    }
                    .disabled(mealName.isEmpty)
                }
            }
        }
    }
    
    private func saveMeal() {
        let meal = MealLog(
            name: mealName,
            timestamp: date,
            photoURL: nil,
            tags: selectedTags,
            notes: notes.isEmpty ? nil : notes
        )
        healthKitManager.saveMeal(meal, image: selectedImage)
    }
} 