import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(title: "Welcome to MyGlucoLog",
                      description: "Your personal glucose tracking companion. Made with love by Vinod ~For my Grandma ❤️",
                      imageName: "heart.fill"),
        OnboardingPage(title: "Track Your Readings", 
                      description: "Log glucose readings and meals easily", 
                      imageName: "chart.line.uptrend.xyaxis"),
        OnboardingPage(title: "Stay Informed", 
                      description: "Get insights and reminders to stay on track", 
                      imageName: "bell.fill")
    ]
    
    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(0..<pages.count, id: \.self) { index in
                VStack(spacing: 20) {
                    Image(systemName: pages[index].imageName)
                        .font(.system(size: 80))
                        .foregroundStyle(Color("AccentColor"))
                        .symbolEffect(.bounce, value: currentPage)
                    
                    Text(pages[index].title)
                        .font(.title)
                        .bold()
                    
                    Text(pages[index].description)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    if index == pages.count - 1 {
                        Button("Get Started") {
                            withAnimation {
                                hasCompletedOnboarding = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                }
                .padding()
                .tag(index)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
} 
