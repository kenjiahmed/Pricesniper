import Foundation
import FirebaseAuth

@MainActor
class AuthService: ObservableObject {
    @Published var user: User? = nil
    @Published var isAuthenticated = false
    @Published var errorMessage: String? = nil
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        self.user = Auth.auth().currentUser
        self.isAuthenticated = (user != nil)
        
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isAuthenticated = (user != nil)
            }
        }
    }
    
    deinit {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signIn(email: String, password: String) async {
        errorMessage = nil
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func signUp(email: String, password: String) async {
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.user = result.user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func signOut() {
        errorMessage = nil
        try? Auth.auth().signOut()
        self.user = nil
        self.isAuthenticated = false
    }
}