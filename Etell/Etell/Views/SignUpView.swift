import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authService: FirebaseAuthService
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.dismiss) var dismiss
    @State private var confirmPassword = ""
    @State private var enableFaceID = false
    @StateObject private var viewModel = AuthViewModel(authService: FirebaseAuthService(), notificationService: NotificationService())
    
    var isFormValid: Bool {
        !viewModel.fullName.isEmpty && viewModel.isFormValid && confirmPassword == viewModel.password && viewModel.password.count >= 6
    }
    
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
                        // Navigation Header
                        SignUpNavigationHeader(dismiss: dismiss)
                            .padding(.top, max(geometry.safeAreaInsets.top, 20))
                        
                        // Hero Section
                        SignUpHeroSection()
                        
                        // Main Content Card
                        VStack(spacing: 32) {
                            // Sign Up Form
                            SignUpFormSection(
                                viewModel: viewModel,
                                confirmPassword: $confirmPassword
                            )
                            
                            // Biometric Section
                            if notificationService.isFaceIDAvailable {
                                SignUpBiometricSection(
                                    enableFaceID: $enableFaceID,
                                    notificationService: notificationService
                                )
                            }
                            
                            // Action Buttons
                            SignUpActionButtons(
                                viewModel: viewModel,
                                isFormValid: isFormValid,
                                authService: authService,
                                notificationService: notificationService,
                                enableFaceID: enableFaceID,
                                dismiss: dismiss
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
        .onAppear {
            viewModel.updateServices(authService: authService, notificationService: notificationService)
        }
    }
}

// MARK: - SignUp UI Components

struct SignUpNavigationHeader: View {
    let dismiss: DismissAction
    
    var body: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 17, weight: .medium))
                }
                .foregroundStyle(.blue)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

struct SignUpHeroSection: View {
    var body: some View {
        VStack(spacing: 16) {
            // App Icon/Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 8)
            
            // Welcome Text
            VStack(spacing: 8) {
                Text("Create Account")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Join Etell and optimize your network experience")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

struct SignUpFormSection: View {
    @ObservedObject var viewModel: AuthViewModel
    @Binding var confirmPassword: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Full Name Field
            SignUpTextField(
                title: "Full Name",
                text: $viewModel.fullName,
                placeholder: "Enter your full name",
                icon: "person",
                keyboardType: .default,
                autocapitalization: .words
            )
            
            // Email Field
            SignUpTextField(
                title: "Email Address",
                text: $viewModel.email,
                placeholder: "Enter your email",
                icon: "envelope",
                keyboardType: .emailAddress,
                autocapitalization: .never
            )
            
            // Password Field
            SignUpSecureField(
                title: "Password",
                text: $viewModel.password,
                placeholder: "Create a strong password",
                icon: "lock",
                showValidation: true
            )
            
            // Confirm Password Field
            SignUpSecureField(
                title: "Confirm Password",
                text: $confirmPassword,
                placeholder: "Confirm your password",
                icon: "lock.shield",
                showValidation: false,
                confirmationPassword: viewModel.password
            )
        }
    }
}

struct SignUpTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never
    
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
                    .textInputAutocapitalization(autocapitalization)
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

struct SignUpSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var showValidation: Bool = false
    var confirmationPassword: String = ""
    
    @FocusState private var isFocused: Bool
    @State private var isSecure = true
    
    private var isPasswordValid: Bool {
        text.count >= 6
    }
    
    private var passwordsMatch: Bool {
        confirmationPassword.isEmpty || text == confirmationPassword
    }
    
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
            
            // Validation Messages
            if showValidation && !text.isEmpty && !isPasswordValid {
                Label("Password must be at least 6 characters", systemImage: "exclamationmark.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.red)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            if !confirmationPassword.isEmpty && !passwordsMatch {
                Label("Passwords do not match", systemImage: "exclamationmark.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.red)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPasswordValid)
        .animation(.easeInOut(duration: 0.3), value: passwordsMatch)
    }
}

struct SignUpBiometricSection: View {
    @Binding var enableFaceID: Bool
    let notificationService: NotificationService
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notificationService.biometryType == .faceID ? "faceid" : "touchid")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.green)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Enable \(notificationService.biometryType == .faceID ? "Face ID" : "Touch ID")")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("Quick and secure access after account creation")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $enableFaceID)
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

struct SignUpActionButtons: View {
    @ObservedObject var viewModel: AuthViewModel
    let isFormValid: Bool
    let authService: FirebaseAuthService
    let notificationService: NotificationService
    let enableFaceID: Bool
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 16) {
            // Create Account Button
            Button(action: {
                Task {
                    do {
                        try await authService.signUp(
                            email: viewModel.email,
                            password: viewModel.password,
                            displayName: viewModel.fullName.isEmpty ? nil : viewModel.fullName
                        )
                        
                        if authService.isAuthenticated {
                            if enableFaceID {
                                notificationService.enableFaceID()
                            }
                            dismiss()
                        }
                    } catch {
                        // Handle error
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.white)
                    }
                    Text(viewModel.isLoading ? "Creating Account..." : "Create Account")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isFormValid && !viewModel.isLoading
                            ? [.green, .green.opacity(0.8)]
                            : [Color(.systemGray3), Color(.systemGray4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .shadow(
                    color: isFormValid && !viewModel.isLoading
                        ? .green.opacity(0.3)
                        : .clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .disabled(!isFormValid || viewModel.isLoading)
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isFormValid)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
            
            // Sign In Link
            HStack(spacing: 4) {
                Text("Already have an account?")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Sign In")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.top, 8)
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(FirebaseAuthService())
        .environmentObject(NotificationService())
}
