import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var authService: FirebaseAuthService
    @EnvironmentObject var notificationService: NotificationService
    @State private var showingSignUp = false
    @StateObject private var viewModel = AuthViewModel(authService: FirebaseAuthService(), notificationService: NotificationService())
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Modern Background with Gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section
                        LoginHeroSection()
                            .padding(.top, max(geometry.safeAreaInsets.top, 20))
                        
                        // Main Content Card
                        VStack(spacing: 32) {
                            // Login Form
                            LoginFormSection(viewModel: viewModel)
                            
                            // Biometric Section
                            if notificationService.isFaceIDAvailable {
                                LoginBiometricSection(
                                    viewModel: viewModel,
                                    notificationService: notificationService,
                                    authService: authService
                                )
                            }
                            
                            // Action Buttons
                            LoginActionButtons(
                                viewModel: viewModel,
                                showingSignUp: $showingSignUp
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.quaternary, lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 20)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
        .onAppear {
            viewModel.updateServices(authService: authService, notificationService: notificationService)
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            if !isAuthenticated {
                viewModel.resetLoginState()
            }
        }
    }
}

// MARK: - Login UI Components

struct LoginHeroSection: View {
    var body: some View {
        VStack(spacing: 16) {
            // App Icon/Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 8)
            
            // Welcome Text
            VStack(spacing: 8) {
                Text("Welcome to Etell")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Your network optimization companion")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}

struct LoginFormSection: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Email Field
            LoginTextField(
                title: "Email",
                text: $viewModel.email,
                placeholder: "Enter your email",
                icon: "envelope",
                keyboardType: .emailAddress
            )
            
            // Password Field
            LoginSecureField(
                title: "Password",
                text: $viewModel.password,
                placeholder: "Enter your password",
                icon: "lock"
            )
            
            // Forgot Password
            HStack {
                Spacer()
                Button(action: {
                    Task {
                        await viewModel.resetPassword()
                    }
                }) {
                    Text("Forgot password?")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.blue)
                }
                .disabled(viewModel.isLoading)
            }
        }
    }
}

struct LoginTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isFocused ? .blue : .secondary)
                    .frame(width: 20, height: 20)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .focused($isFocused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.quinary, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? .blue : .clear, lineWidth: 2)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
        }
    }
}

struct LoginSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    @FocusState private var isFocused: Bool
    @State private var isSecure = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isFocused ? .blue : .secondary)
                    .frame(width: 20, height: 20)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(.system(size: 16))
                .focused($isFocused)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSecure.toggle()
                    }
                }) {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.quinary, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? .blue : .clear, lineWidth: 2)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
        }
    }
}

struct LoginBiometricSection: View {
    @ObservedObject var viewModel: AuthViewModel
    let notificationService: NotificationService
    let authService: FirebaseAuthService
    
    var body: some View {
        VStack(spacing: 16) {
            // Biometric Setup Toggle
            if !authService.hasBiometricCredentials() {
                LoginBiometricToggle(
                    viewModel: viewModel,
                    notificationService: notificationService
                )
            }
            
            // Biometric Login Button
            if authService.hasBiometricCredentials() && !viewModel.isLoading {
                LoginBiometricButton(
                    viewModel: viewModel,
                    notificationService: notificationService
                )
            }
        }
    }
}

struct LoginBiometricToggle: View {
    @ObservedObject var viewModel: AuthViewModel
    let notificationService: NotificationService
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "faceid")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Enable Face ID")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("Quick and secure access to your account")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $viewModel.enableFaceID)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary, lineWidth: 0.5)
        )
    }
}

struct LoginBiometricButton: View {
    @ObservedObject var viewModel: AuthViewModel
    let notificationService: NotificationService
    
    var body: some View {
        Button(action: {
            Task {
                await viewModel.signInWithBiometrics()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "faceid")
                    .font(.system(size: 20, weight: .medium))
                
                Text("Sign in with Face ID")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct LoginActionButtons: View {
    @ObservedObject var viewModel: AuthViewModel
    @Binding var showingSignUp: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Login Button
            Button(action: {
                Task {
                    await viewModel.signIn()
                }
            }) {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.white)
                    }
                    Text(viewModel.isLoading ? "Signing In..." : "Sign In")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: viewModel.isFormValid && !viewModel.isLoading 
                            ? [.blue, .blue.opacity(0.8)]
                            : [Color(.systemGray3), Color(.systemGray4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .shadow(
                    color: viewModel.isFormValid && !viewModel.isLoading 
                        ? .blue.opacity(0.3) 
                        : .clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .disabled(!viewModel.isFormValid || viewModel.isLoading)
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isFormValid)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
            
            // Divider
            HStack {
                Rectangle()
                    .fill(.quaternary)
                    .frame(height: 1)
                
                Text("or")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(.quaternary)
                    .frame(height: 1)
            }
            
            // Sign Up Button
            Button(action: {
                showingSignUp = true
            }) {
                Text("Create Account")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.blue.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(FirebaseAuthService())
            .environmentObject(NotificationService())
    }
}
