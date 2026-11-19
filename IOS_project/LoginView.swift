import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.14), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.16))
                                .frame(width: 84, height: 84)
                            Image(systemName: "scope")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundStyle(.blue)
                        }
                        
                        Text("Price Sniper Pro")
                            .font(.largeTitle.bold())
                        
                        Text(isSignUp ? "Create an account to sync your targets" : "Sign in to track prices and spot fake sales")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.secondary)
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        
                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.secondary)
                            SecureField("Password (6+ chars)", text: $password)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                    }
                    
                    if let error = authService.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(error)
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    Button {
                        Task {
                            isLoading = true
                            if isSignUp {
                                await authService.signUp(email: email, password: password)
                            } else {
                                await authService.signIn(email: email, password: password)
                            }
                            isLoading = false
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        } else {
                            Text(isSignUp ? "Create Account" : "Sign In")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || password.count < 6 || isLoading)
                    
                    Button {
                        withAnimation {
                            isSignUp.toggle()
                            authService.errorMessage = nil
                        }
                    } label: {
                        Text(isSignUp ? "Already have an account? Sign In" : "New here? Create an account")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.blue)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}