import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct CustomerSupportView: View {
    @State private var showingFAQ = false
    @State private var showingLiveChat = false
    @State private var showingIssueReport = false
    @State private var showingAppointmentBooking = false
    @EnvironmentObject var notificationService: NotificationService
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        SupportHeroSection()
                        QuickSupportSection(
                            showingFAQ: $showingFAQ,
                            showingLiveChat: $showingLiveChat,
                            showingIssueReport: $showingIssueReport
                        )
                        BookAppointmentSection(showingAppointmentBooking: $showingAppointmentBooking)
                        ContactMethodsSection()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Support")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingFAQ) {
                ModernFAQView()
            }
            .sheet(isPresented: $showingLiveChat) {
                ModernLiveChatView()
            }
            .sheet(isPresented: $showingIssueReport) {
                ModernIssueReportView()
            }
            .sheet(isPresented: $showingAppointmentBooking) {
                AppointmentBookingView()
                    .environmentObject(notificationService)
            }
        }
    }
}

// MARK: - Support Hero Section

struct SupportHeroSection: View {
    var body: some View {
        VStack(spacing: 16) {
            // Gradient Hero Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "headphones")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.white)
            }
            .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 8) {
                Text("How can we help you?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Our support team is here to assist you 24/7")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Quick Support Section

struct QuickSupportSection: View {
    @Binding var showingFAQ: Bool
    @Binding var showingLiveChat: Bool
    @Binding var showingIssueReport: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Support")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // FAQ Card
                SupportActionCard(
                    icon: "questionmark.circle.fill",
                    title: "FAQ",
                    subtitle: "Find quick answers",
                    gradientColors: [.blue, .purple],
                    badge: "Popular"
                ) {
                    showingFAQ = true
                }
                
                // Live Chat Card
                SupportActionCard(
                    icon: "message.fill",
                    title: "Live Chat",
                    subtitle: "Chat with support",
                    gradientColors: [.green, .mint],
                    badge: "24/7"
                ) {
                    showingLiveChat = true
                }
                
                // Report Issue Card
                SupportActionCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Report Issue",
                    subtitle: "Submit a problem",
                    gradientColors: [.orange, .red]
                ) {
                    showingIssueReport = true
                }
                
                // Call Support Card
                SupportActionCard(
                    icon: "phone.fill",
                    title: "Call Support",
                    subtitle: "Speak with an expert",
                    gradientColors: [.indigo, .blue]
                ) {
                    if let phoneURL = URL(string: "tel:+1234567890") {
                        UIApplication.shared.open(phoneURL)
                    }
                }
            }
        }
    }
}

struct SupportActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    let badge: String?
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        gradientColors: [Color],
        badge: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.gradientColors = gradientColors
        self.badge = badge
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 8) {
                        // Gradient Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text(title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                            
                            Text(subtitle)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Badge
                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red, in: Capsule())
                            .offset(x: 8, y: -8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.quaternary, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Book Appointment Section

struct BookAppointmentSection: View {
    @Binding var showingAppointmentBooking: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Book an Appointment")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
            
            AppointmentCard(showingAppointmentBooking: $showingAppointmentBooking)
        }
    }
}

struct AppointmentCard: View {
    @Binding var showingAppointmentBooking: Bool
    
    var body: some View {
        Button(action: { showingAppointmentBooking = true }) {
            VStack(spacing: 16) {
                // Header with gradient icon
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.teal, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Schedule a Consultation")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Get personalized support from our experts")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                
                // Features
                VStack(spacing: 12) {
                    AppointmentFeature(
                        icon: "person.2.fill",
                        title: "One-on-One Support",
                        description: "Dedicated technician assistance"
                    )
                    
                    AppointmentFeature(
                        icon: "video.fill",
                        title: "Virtual or In-Person",
                        description: "Choose your preferred meeting style"
                    )
                    
                    AppointmentFeature(
                        icon: "clock.fill",
                        title: "Flexible Scheduling",
                        description: "Book at your convenience"
                    )
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.quaternary, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct AppointmentFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.teal)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Contact Methods Section

struct ContactMethodsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Methods")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 12) {
                // Phone Contact
                ContactMethodCard(
                    icon: "phone.fill",
                    title: "Phone Support",
                    subtitle: "+1 (555) 123-4567",
                    description: "Available 24/7 for urgent issues",
                    gradientColors: [.blue, .cyan]
                ) {
                    if let phoneURL = URL(string: "tel:+15551234567") {
                        UIApplication.shared.open(phoneURL)
                    }
                }
                
                // Email Contact
                ContactMethodCard(
                    icon: "envelope.fill",
                    title: "Email Support",
                    subtitle: "support@etell.com",
                    description: "Response within 24 hours",
                    gradientColors: [.purple, .pink]
                ) {
                    if let emailURL = URL(string: "mailto:support@etell.com") {
                        UIApplication.shared.open(emailURL)
                    }
                }
            }
        }
    }
}

struct ContactMethodCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let gradientColors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Gradient Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.quaternary, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Support Views

struct ModernFAQView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var expandedItems = Set<UUID>()
    
    var filteredFAQs: [FAQ] {
        if searchText.isEmpty {
            return FAQ.mockFAQs
        } else {
            return FAQ.mockFAQs.filter { faq in
                faq.question.localizedCaseInsensitiveContains(searchText) ||
                faq.answer.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Modern Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    TextField("Search FAQs...", text: $searchText)
                        .font(.system(size: 16))
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.quinary, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredFAQs) { faq in
                            ModernFAQCard(
                                faq: faq,
                                isExpanded: expandedItems.contains(faq.id)
                            ) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    if expandedItems.contains(faq.id) {
                                        expandedItems.remove(faq.id)
                                    } else {
                                        expandedItems.insert(faq.id)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Frequently Asked Questions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ModernFAQCard: View {
    let faq: FAQ
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Question Header
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Text(faq.question)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            
            // Answer Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    Text(faq.answer)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary, lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

struct ModernLiveChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var messages: [SupportChatMessage] = SupportChatMessage.mockMessages
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat Messages
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            ChatMessageRow(message: message)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color(.systemGray6))
                
                // Message Input
                HStack(spacing: 12) {
                    TextField("Type your message...", text: $messageText, axis: .vertical)
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.quinary, in: RoundedRectangle(cornerRadius: 20))
                        .lineLimit(1...4)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.blue, in: Circle())
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.regularMaterial)
            }
            .navigationTitle("Live Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let newMessage = SupportChatMessage(
            id: UUID(),
            text: messageText,
            isFromUser: true,
            timestamp: Date()
        )
        
        messages.append(newMessage)
        messageText = ""
        
        // Simulate response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let response = SupportChatMessage(
                id: UUID(),
                text: "Thank you for your message. Our support team will assist you shortly.",
                isFromUser: false,
                timestamp: Date()
            )
            messages.append(response)
        }
    }
}

struct ChatMessageRow: View {
    let message: SupportChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 16))
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 60)
            }
        }
    }
}

struct ModernIssueReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var issueTitle = ""
    @State private var issueDescription = ""
    @State private var selectedCategory = "Technical Issue"
    @State private var includeDeviceInfo = true
    @State private var isSubmitting = false
    
    private let db = Firestore.firestore()
    
    private let categories = [
        "Technical Issue",
        "Billing Question",
        "Service Outage",
        "Feature Request",
        "Account Access",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Issue Category")
                }
                
                Section {
                    TextField("Brief description of the issue", text: $issueTitle)
                        .font(.system(size: 16))
                } header: {
                    Text("Issue Title")
                }
                
                Section {
                    TextField("Please describe your issue in detail...", text: $issueDescription, axis: .vertical)
                        .font(.system(size: 16))
                        .lineLimit(5...10)
                } header: {
                    Text("Description")
                }
                
                Section {
                    Toggle("Include device information", isOn: $includeDeviceInfo)
                        .font(.system(size: 16))
                } header: {
                    Text("Additional Information")
                } footer: {
                    Text("This helps our support team diagnose technical issues faster")
                }
                
                Section {
                    Button(action: {
                        Task {
                            await submitReport()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.9)
                                    .tint(.white)
                                Text("Submitting...")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.white)
                            } else {
                                Text("Submit Report")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(issueTitle.isEmpty || issueDescription.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Report Issue")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitReport() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found - cannot submit issue report")
            return
        }
        
        isSubmitting = true
        
        do {
            let reportData: [String: Any] = [
                "id": UUID().uuidString,
                "title": issueTitle,
                "description": issueDescription,
                "category": selectedCategory,
                "includeDeviceInfo": includeDeviceInfo,
                "status": "Open",
                "priority": "Medium",
                "submittedAt": Timestamp(),
                "userId": userId
            ]
            
            print("📋 Submitting issue report for user: \(userId)")
            print("📋 Report data: \(reportData)")
            
            try await db.collection("users")
                .document(userId)
                .collection("supportReports")
                .addDocument(data: reportData)
            
            print("✅ Issue report submitted successfully")
            
            await MainActor.run {
                isSubmitting = false
                dismiss()
            }
            
        } catch {
            print("❌ Error submitting issue report: \(error.localizedDescription)")
            await MainActor.run {
                isSubmitting = false
                // You could show an error alert here
            }
        }
    }
}

struct AppointmentBookingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var notificationService: NotificationService
    @State private var selectedAppointmentType = "Technical Support"
    @State private var selectedMeetingStyle = "Virtual"
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var customerName = ""
    @State private var customerEmail = ""
    @State private var customerPhone = ""
    @State private var appointmentNotes = ""
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    
    private let db = Firestore.firestore()
    
    private let appointmentTypes = [
        "Technical Support",
        "Network Optimization",
        "Device Setup",
        "Signal Analysis",
        "Billing Consultation",
        "General Consultation"
    ]
    
    private let meetingStyles = ["Virtual", "In-Person"]
    
    var body: some View {
        NavigationView {
            Form {
                // Appointment Type Section
                Section {
                    Picker("Service Type", selection: $selectedAppointmentType) {
                        ForEach(appointmentTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Appointment Type")
                } footer: {
                    Text("Select the type of support you need")
                }
                
                // Meeting Style Section
                Section {
                    Picker("Meeting Style", selection: $selectedMeetingStyle) {
                        ForEach(meetingStyles, id: \.self) { style in
                            HStack {
                                Image(systemName: style == "Virtual" ? "video.fill" : "location.fill")
                                    .foregroundStyle(style == "Virtual" ? .blue : .green)
                                Text(style)
                            }
                            .tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Meeting Preference")
                } footer: {
                    Text(selectedMeetingStyle == "Virtual" ? "We'll send you a video call link" : "Meeting at our service center or your location")
                }
                
                // Date & Time Section
                Section {
                    DatePicker(
                        "Preferred Date",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    
                    DatePicker(
                        "Preferred Time",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                } header: {
                    Text("Schedule")
                } footer: {
                    Text("Select your preferred date and time. All times are in your local timezone.")
                }
                
                // Contact Information Section
                Section {
                    TextField("Full Name", text: $customerName)
                        .font(.system(size: 16))
                    
                    TextField("Email Address", text: $customerEmail)
                        .font(.system(size: 16))
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                    
                    TextField("Phone Number", text: $customerPhone)
                        .font(.system(size: 16))
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                } header: {
                    Text("Contact Information")
                } footer: {
                    Text("We'll use this information to confirm your appointment")
                }
                
                // Additional Notes Section
                Section {
                    TextField(
                        "Describe your issue or what you'd like help with...",
                        text: $appointmentNotes,
                        axis: .vertical
                    )
                    .font(.system(size: 16))
                    .lineLimit(3...6)
                } header: {
                    Text("Additional Notes (Optional)")
                } footer: {
                    Text("Help us prepare for your appointment")
                }
                
                // Booking Summary
                Section {
                    VStack(spacing: 12) {
                        AppointmentSummaryRow(
                            icon: "briefcase.fill",
                            title: "Service",
                            value: selectedAppointmentType
                        )
                        
                        AppointmentSummaryRow(
                            icon: selectedMeetingStyle == "Virtual" ? "video.fill" : "location.fill",
                            title: "Meeting Style",
                            value: selectedMeetingStyle
                        )
                        
                        AppointmentSummaryRow(
                            icon: "calendar",
                            title: "Date & Time",
                            value: "\(selectedDate.formatted(date: .abbreviated, time: .omitted)) at \(selectedTime.formatted(date: .omitted, time: .shortened))"
                        )
                    }
                } header: {
                    Text("Appointment Summary")
                }
                
                // Book Button Section
                Section {
                    Button(action: bookAppointment) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Spacer()
                            Text(isSubmitting ? "Booking..." : "Book Appointment")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(.teal, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSubmitting || customerName.isEmpty || customerEmail.isEmpty || customerPhone.isEmpty)
                }
            }
            .navigationTitle("Book Appointment")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Appointment Booked!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your appointment has been scheduled. You'll receive a confirmation email shortly.")
            }
        }
    }
    
    private func bookAppointment() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found - cannot book appointment")
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                // Combine date and time for the full appointment datetime
                let calendar = Calendar.current
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
                
                var fullDateComponents = DateComponents()
                fullDateComponents.year = dateComponents.year
                fullDateComponents.month = dateComponents.month
                fullDateComponents.day = dateComponents.day
                fullDateComponents.hour = timeComponents.hour
                fullDateComponents.minute = timeComponents.minute
                
                guard let appointmentDateTime = calendar.date(from: fullDateComponents) else {
                    print("❌ Failed to create appointment datetime")
                    await MainActor.run {
                        isSubmitting = false
                    }
                    return
                }
                
                let appointmentId = UUID().uuidString
                let appointmentData: [String: Any] = [
                    "id": appointmentId,
                    "appointmentType": selectedAppointmentType,
                    "meetingStyle": selectedMeetingStyle,
                    "appointmentDateTime": appointmentDateTime,
                    "customerName": customerName,
                    "customerEmail": customerEmail,
                    "customerPhone": customerPhone,
                    "notes": appointmentNotes,
                    "status": "Scheduled",
                    "bookedAt": Timestamp(),
                    "userId": userId,
                    "notificationScheduled": true
                ]
                
                print("📅 Booking appointment for user: \(userId)")
                print("📅 Appointment datetime: \(appointmentDateTime)")
                print("📅 Appointment data: \(appointmentData)")
                
                // Save to Firestore
                try await db.collection("users")
                    .document(userId)
                    .collection("appointments")
                    .document(appointmentId)
                    .setData(appointmentData)
                
                // Schedule local notifications using NotificationService
                notificationService.scheduleAppointmentReminder(
                    appointmentId: appointmentId,
                    appointmentDateTime: appointmentDateTime,
                    appointmentType: selectedAppointmentType
                )
                
                print("✅ Appointment booked successfully with local notifications scheduled")
                
                await MainActor.run {
                    isSubmitting = false
                    showingSuccess = true
                }
                
            } catch {
                print("❌ Error booking appointment: \(error.localizedDescription)")
                await MainActor.run {
                    isSubmitting = false
                    // You could show an error alert here
                }
            }
        }
    }
}

struct AppointmentSummaryRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.teal)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Data Models

struct SupportChatMessage: Identifiable {
    let id: UUID
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    
    static let mockMessages = [
        SupportChatMessage(
            id: UUID(),
            text: "Hello! How can I help you today?",
            isFromUser: false,
            timestamp: Date().addingTimeInterval(-300)
        ),
        SupportChatMessage(
            id: UUID(),
            text: "Hi, I'm having trouble with my signal strength",
            isFromUser: true,
            timestamp: Date().addingTimeInterval(-240)
        ),
        SupportChatMessage(
            id: UUID(),
            text: "I'd be happy to help you with signal issues. Can you tell me your current location?",
            isFromUser: false,
            timestamp: Date().addingTimeInterval(-180)
        )
    ]
}

#Preview {
    CustomerSupportView()
}
