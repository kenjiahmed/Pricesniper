import SwiftUI
import FirebaseCore

@main
struct PriceSniperApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var repository = ProductRepository()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootGateView()
                .environmentObject(authService)
                .environmentObject(repository)
        }
    }
}

struct RootGateView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var repository: ProductRepository
    
    var body: some View {
        Group {
            if authService.isAuthenticated, let user = authService.user {
                ContentView()
                    .onAppear {
                        repository.startListening(for: user.uid)
                    }
                    .onDisappear {
                        repository.stopListening()
                    }
            } else {
                LoginView()
            }
        }
    }
}