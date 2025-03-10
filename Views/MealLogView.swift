import SwiftUI
import PhotosUI

struct MealLogView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var showingAddMeal = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(healthKitManager.meals) { meal in
                    MealLogRow(meal: meal)
                }
            }
            .navigationTitle("Meal Log")
            .toolbar {
                Button(action: { showingAddMeal = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView()
            }
            .background(Theme.backgroundColor)
            .scrollContentBackground(.hidden)
            .listStyle(PlainListStyle())
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MealLogRow: View {
    let meal: MealLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(meal.name)
                    .font(.headline)
                Spacer()
                Text(meal.timestamp, style: .time)
                    .foregroundColor(.secondary)
            }
            
            if let url = meal.photoURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .cornerRadius(8)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .cornerRadius(8)
                }
            }
            
            FlowLayout(alignment: .leading, spacing: 8) {
                ForEach(Array(meal.tags), id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            if let notes = meal.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .listRowBackground(Theme.cardBackground)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
} 