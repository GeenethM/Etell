//
//  ProfileView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

// MARK: - Main Profile View
struct ProfileView: View {
    @EnvironmentObject var authService: FirebaseAuthService
    @EnvironmentObject var notificationService: NotificationService
    @State private var showingSignOutAlert = false
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var darkModeEnabled = false
    @State private var showingAccountDetails = false
    @State private var showingPasswordChange = false
    @State private var showingPendingOrders = false
    @State private var pendingOrders: [Order] = []
    @State private var isLoadingOrders = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Profile Header Card
                    ModernProfileHeader()
                    
                    // Security Settings
                    ModernSecuritySection()
                    
                    // App Preferences
                    ModernPreferencesSection()
                    
                    // Account Management
                    ModernAccountSection()
                    
                    // Logout Section
                    ModernLogoutSection()
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(.ultraThinMaterial.opacity(0.5))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedImage,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedImage) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        profileImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Sign Out", role: .destructive) {
                print("🟠 Sign Out confirmed - calling authService.signOut()")
                authService.signOut()
                notificationService.disableFaceID()
                print("🟠 Sign out process completed")
            }
            Button("Cancel", role: .cancel) { 
                print("🟠 Sign Out cancelled")
            }
        } message: {
            Text("Are you sure you want to sign out? This will clear all your login data and return you to the login page.")
        }
        .sheet(isPresented: $showingPendingOrders) {
            PendingOrdersView(orders: $pendingOrders, isLoading: $isLoadingOrders)
        }
        .environmentObject(authService)
        .environmentObject(notificationService)
        .onAppear {
            // Refresh notification permission status when view appears
            notificationService.requestNotificationPermission()
            // Load pending orders
            Task {
                await loadPendingOrders()
            }
        }
    }
    
    // MARK: - Profile Header
    @ViewBuilder
    private func ModernProfileHeader() -> some View {
        VStack(spacing: 20) {
            // Profile Image with Edit Button
            ZStack {
                Button {
                    showingImagePicker = true
                } label: {
                    Group {
                        if let profileImage {
                            profileImage
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if let imageURL = authService.currentUser?.profileImageURL {
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(.secondary)
                                    )
                            }
                        } else {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.secondary)
                                )
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(.quaternary, lineWidth: 2)
                    )
                }
                
                // Edit Button
                Button {
                    showingImagePicker = true
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(.blue.gradient, in: Circle())
                        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .offset(x: 35, y: 35)
            }
            
            // User Information
            VStack(spacing: 8) {
                Text(authService.currentUser?.displayName ?? "John Smith")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(authService.currentUser?.email ?? "johnsmith@example.com")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Status Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.green.opacity(0.1), in: Capsule())
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Security Section
    @ViewBuilder
    private func ModernSecuritySection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Security")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 0) {
                ModernToggleRow(
                    icon: "faceid",
                    title: "Face ID",
                    subtitle: notificationService.isFaceIDAvailable ? "Use Face ID to unlock the app" : "Face ID not available on this device",
                    isOn: $notificationService.isFaceIDEnabled,
                    iconColor: .blue,
                    action: { enabled in
                        if enabled {
                            Task {
                                let success = await notificationService.authenticateWithBiometrics()
                                if success {
                                    notificationService.enableFaceID()
                                } else {
                                    notificationService.isFaceIDEnabled = false
                                }
                            }
                        } else {
                            notificationService.disableFaceID()
                        }
                    }
                )
                .disabled(!notificationService.isFaceIDAvailable)
                
                Divider()
                    .padding(.leading, 60)
                
                ModernSettingsRow(
                    icon: "lock.shield",
                    title: "Change Password",
                    subtitle: "Update your account password",
                    iconColor: .orange,
                    showChevron: true
                ) {
                    showingPasswordChange = true
                }
                
                Divider()
                    .padding(.leading, 60)
                
                ModernSettingsRow(
                    icon: "key",
                    title: "Two-Factor Authentication",
                    subtitle: "Add an extra layer of security",
                    iconColor: .green,
                    showChevron: true
                ) {
                    // Handle 2FA
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Preferences Section
    @ViewBuilder
    private func ModernPreferencesSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 0) {
                ModernToggleRow(
                    icon: "bell.badge",
                    title: "Push Notifications",
                    subtitle: notificationService.isAuthorized ? "Notifications are enabled" : "Enable to receive alerts and updates",
                    isOn: $notificationService.isAuthorized,
                    iconColor: .red,
                    action: { enabled in
                        if enabled {
                            notificationService.requestNotificationPermission()
                        } else {
                            // Open Settings to disable notifications
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                
                ModernToggleRow(
                    icon: "moon.fill",
                    title: "Dark Mode",
                    subtitle: "Use dark appearance",
                    isOn: $darkModeEnabled,
                    iconColor: .indigo
                )
                
                Divider()
                    .padding(.leading, 60)
                
                ModernSettingsRow(
                    icon: "globe",
                    title: "Language",
                    subtitle: "English",
                    iconColor: .cyan,
                    showChevron: true
                ) {
                    // Handle language
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Account Section
    @ViewBuilder
    private func ModernAccountSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 0) {
                ModernSettingsRow(
                    icon: "person.circle",
                    title: "Account Details",
                    subtitle: "Manage your personal information",
                    iconColor: .blue,
                    showChevron: true
                ) {
                    showingAccountDetails = true
                }
                
                Divider()
                    .padding(.leading, 60)
                
                ModernSettingsRow(
                    icon: "bag.badge",
                    title: "Pending Orders",
                    subtitle: pendingOrders.isEmpty ? "No pending orders" : "\(pendingOrders.count) order\(pendingOrders.count == 1 ? "" : "s")",
                    iconColor: .orange,
                    showChevron: true
                ) {
                    showingPendingOrders = true
                    Task {
                        await loadPendingOrders()
                    }
                }
                
                Divider()
                    .padding(.leading, 60)
                
                ModernSettingsRow(
                    icon: "doc.text",
                    title: "Privacy Policy",
                    subtitle: "Read our privacy policy",
                    iconColor: .purple,
                    showChevron: true
                ) {
                    // Handle privacy policy
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Logout Section
    @ViewBuilder
    private func ModernLogoutSection() -> some View {
        Button {
            showingSignOutAlert = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.title3)
                    .foregroundStyle(.red)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign Out")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                    
                    Text("Sign out of your account")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(.red.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.red.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Settings Row
struct ModernSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let showChevron: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor.gradient)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Toggle Row
struct ModernToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let iconColor: Color
    let action: ((Bool) -> Void)?
    
    init(icon: String, title: String, subtitle: String, isOn: Binding<Bool>, iconColor: Color, action: ((Bool) -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.iconColor = iconColor
        self.action = action
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor.gradient)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .onChange(of: isOn) { _, newValue in
                    action?(newValue)
                }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
}

// MARK: - Helper Functions
extension ProfileView {
    private func loadPendingOrders() async {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ No authenticated user found")
            return
        }
        
        DispatchQueue.main.async {
            self.isLoadingOrders = true
        }
        
        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("users")
                .document(currentUser.uid)
                .collection("orders")
                .order(by: "orderDate", descending: true)
                .getDocuments()
            
            let orders = snapshot.documents.compactMap { document in
                return Order.fromFirestoreData(document.data())
            }
            
            DispatchQueue.main.async {
                self.pendingOrders = orders
                self.isLoadingOrders = false
            }
            
            print("✅ Loaded \(orders.count) orders for user")
        } catch {
            print("❌ Error loading orders: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isLoadingOrders = false
            }
        }
    }
}

// MARK: - Pending Orders View
struct PendingOrdersView: View {
    @Binding var orders: [Order]
    @Binding var isLoading: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading Orders...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                } else if orders.isEmpty {
                    // Empty State
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Image(systemName: "bag")
                                .font(.system(size: 50))
                                .foregroundStyle(.secondary)
                            
                            VStack(spacing: 8) {
                                Text("No Orders Yet")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                Text("Your order history will appear here")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        Button("Browse Store") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(.blue.gradient, in: Capsule())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Orders List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(orders) { order in
                                OrderRowView(order: order)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Your Orders")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - Order Row View
struct OrderRowView: View {
    let order: Order
    @State private var showingOrderDetail = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Order Header
            HStack(alignment: .top, spacing: 12) {
                // Order Status Icon
                VStack {
                    Image(systemName: order.status.icon)
                        .font(.title3)
                        .foregroundStyle(colorForStatus(order.status))
                        .frame(width: 40, height: 40)
                        .background(colorForStatus(order.status).opacity(0.1), in: Circle())
                }
                
                // Order Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Order #\(String(order.id.prefix(8)))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Text(order.status.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(colorForStatus(order.status))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(colorForStatus(order.status).opacity(0.1), in: Capsule())
                    }
                    
                    Text("\(order.items.count) item\(order.items.count == 1 ? "" : "s") • $\(order.totalAmount, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Ordered \(order.orderDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let delivery = order.estimatedDelivery {
                        Text("Estimated delivery: \(delivery.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(16)
            
            // Order Items Preview
            if !order.items.isEmpty {
                Divider()
                    .padding(.horizontal, 16)
                
                VStack(spacing: 8) {
                    ForEach(order.items.prefix(2)) { item in
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: item.productImageURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Image(systemName: "cube.box")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    )
                            }
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.productName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                
                                Text("Qty: \(item.quantity) • $\(item.price, specifier: "%.2f")")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    if order.items.count > 2 {
                        Text("and \(order.items.count - 2) more item\(order.items.count - 2 == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 52)
                    }
                }
                .padding(16)
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(UIColor.quaternaryLabel), lineWidth: 0.5)
        )
        .onTapGesture {
            showingOrderDetail = true
        }
        .sheet(isPresented: $showingOrderDetail) {
            OrderDetailView(order: order)
        }
    }
    
    private func colorForStatus(_ status: Order.OrderStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .processing: return .blue
        case .shipped: return .purple
        case .delivered: return .green
        case .cancelled: return .red
        }
    }
}

// MARK: - Order Detail View
struct OrderDetailView: View {
    let order: Order
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Order Status Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Order Status")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 12) {
                            Image(systemName: order.status.icon)
                                .font(.title)
                                .foregroundStyle(colorForStatus(order.status))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(order.status.rawValue)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                Text("Order #\(String(order.id.prefix(8)))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text("Placed on \(order.orderDate.formatted(date: .complete, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Items Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Order Items")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            ForEach(order.items) { item in
                                HStack(spacing: 12) {
                                    AsyncImage(url: URL(string: item.productImageURL)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Image(systemName: "cube.box")
                                                    .font(.title3)
                                                    .foregroundStyle(.secondary)
                                            )
                                    }
                                    .frame(width: 60, height: 60)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.productName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                            .lineLimit(2)
                                        
                                        Text(item.category)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        HStack {
                                            Text("Qty: \(item.quantity)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            
                                            Spacer()
                                            
                                            Text("$\(item.price, specifier: "%.2f")")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    
                    // Billing Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Billing Information")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(title: "Name", value: order.billingInfo.fullName)
                            DetailRow(title: "Email", value: order.billingInfo.email)
                            DetailRow(title: "Address", value: order.billingInfo.formattedAddress)
                            DetailRow(title: "Payment Method", value: order.paymentMethod)
                        }
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Order Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Order Summary")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Items (\(order.items.count))")
                                Spacer()
                                Text("$\(order.totalAmount, specifier: "%.2f")")
                            }
                            
                            HStack {
                                Text("Shipping")
                                Spacer()
                                Text("Free")
                                    .foregroundStyle(.green)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("$\(order.totalAmount, specifier: "%.2f")")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private func colorForStatus(_ status: Order.OrderStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .processing: return .blue
        case .shipped: return .purple
        case .delivered: return .green
        case .cancelled: return .red
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(FirebaseAuthService())
        .environmentObject(NotificationService())
}