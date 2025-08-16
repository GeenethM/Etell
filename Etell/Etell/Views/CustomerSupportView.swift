//
//  CustomerSupportView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI

struct CustomerSupportView: View {
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var contactForm = ContactForm()
    @State private var showingFormSubmission = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Support Options", selection: $selectedTab) {
                    Text("FAQ").tag(0)
                    Text("Contact").tag(1)
                    Text("Live Chat").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    FAQView(searchText: $searchText)
                        .tag(0)
                    
                    ContactFormView(form: $contactForm, showingSubmission: $showingFormSubmission)
                        .tag(1)
                    
                    LiveChatView()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Customer Support")
        }
    }
}

struct FAQView: View {
    @Binding var searchText: String
    @State private var expandedItems = Set<UUID>()
    
    let faqs = FAQ.mockFAQs
    
    var filteredFAQs: [FAQ] {
        if searchText.isEmpty {
            return faqs
        } else {
            return faqs.filter { faq in
                faq.question.localizedCaseInsensitiveContains(searchText) ||
                faq.answer.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search FAQs...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
            
            // FAQ List
            if filteredFAQs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No FAQs found")
                        .font(.headline)
                    
                    Text("Try searching for something else")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredFAQs) { faq in
                    FAQItem(
                        faq: faq,
                        isExpanded: expandedItems.contains(faq.id)
                    ) {
                        if expandedItems.contains(faq.id) {
                            expandedItems.remove(faq.id)
                        } else {
                            expandedItems.insert(faq.id)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

struct FAQItem: View {
    let faq: FAQ
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                HStack {
                    Text(faq.question)
                        .font(.headline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(faq.answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

struct ContactFormView: View {
    @Binding var form: ContactForm
    @Binding var showingSubmission: Bool
    @State private var isSubmitting = false
    
    var isFormValid: Bool {
        !form.name.isEmpty && !form.email.isEmpty && !form.subject.isEmpty && !form.message.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Contact Information
                ContactInfoSection()
                
                // Form Fields
                VStack(alignment: .leading, spacing: 16) {
                    Text("Send us a message")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Your full name", text: $form.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("your.email@example.com", text: $form.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subject")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Brief description of your issue", text: $form.subject)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                                .background(Color(.systemBackground))
                            
                            if form.message.isEmpty {
                                Text("Please describe your issue in detail...")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                            }
                            
                            TextEditor(text: $form.message)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                        }
                        .frame(height: 120)
                    }
                    
                    Button(action: {
                        submitForm()
                    }) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isSubmitting ? "Sending..." : "Send Message")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid && !isSubmitting ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
            }
            .padding()
        }
        .alert("Message Sent", isPresented: $showingSubmission) {
            Button("OK") {
                clearForm()
            }
        } message: {
            Text("Thank you for contacting us. We'll get back to you within 24 hours.")
        }
    }
    
    private func submitForm() {
        isSubmitting = true
        
        // Simulate form submission
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSubmitting = false
            showingSubmission = true
        }
    }
    
    private func clearForm() {
        form = ContactForm()
    }
}

struct ContactInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Get in Touch")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                ContactInfoRow(icon: "phone.fill", title: "Phone", value: "1-800-ETELL-24", subtitle: "Available 24/7")
                ContactInfoRow(icon: "envelope.fill", title: "Email", value: "support@etell.com", subtitle: "Response within 24 hours")
                ContactInfoRow(icon: "clock.fill", title: "Live Chat", value: "Available now", subtitle: "Instant support")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ContactInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct LiveChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var newMessage = ""
    @State private var isConnected = false
    @State private var isConnecting = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Status
            ChatStatusBar(isConnected: isConnected, isConnecting: isConnecting)
            
            if isConnected {
                // Messages
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            ChatMessageBubble(message: message)
                        }
                    }
                    .padding()
                }
                
                // Message Input
                ChatInputBar(message: $newMessage) {
                    sendMessage()
                }
            } else {
                // Connect to Chat
                VStack(spacing: 20) {
                    Image(systemName: "message.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Live Chat Support")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Get instant help from our support team")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        connectToChat()
                    }) {
                        Text(isConnecting ? "Connecting..." : "Start Chat")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isConnecting ? Color.gray : Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(isConnecting)
                    .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
        }
    }
    
    private func connectToChat() {
        isConnecting = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isConnecting = false
            isConnected = true
            
            // Add welcome message
            let welcomeMessage = ChatMessage(
                id: UUID(),
                text: "Hello! I'm Sarah from Etell support. How can I help you today?",
                isFromUser: false,
                timestamp: Date()
            )
            messages.append(welcomeMessage)
        }
    }
    
    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(
            id: UUID(),
            text: newMessage,
            isFromUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        let messageText = newMessage
        newMessage = ""
        
        // Simulate response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let response = generateMockResponse(to: messageText)
            let supportMessage = ChatMessage(
                id: UUID(),
                text: response,
                isFromUser: false,
                timestamp: Date()
            )
            messages.append(supportMessage)
        }
    }
    
    private func generateMockResponse(to message: String) -> String {
        let lowercaseMessage = message.lowercased()
        
        if lowercaseMessage.contains("slow") || lowercaseMessage.contains("speed") {
            return "I understand you're experiencing slow internet speeds. Let me help you troubleshoot this. Can you tell me what speeds you're currently getting?"
        } else if lowercaseMessage.contains("router") || lowercaseMessage.contains("wifi") {
            return "I can help with router and WiFi issues. Have you tried restarting your router recently? Also, you might want to check our signal calibration tool in the app."
        } else if lowercaseMessage.contains("billing") || lowercaseMessage.contains("plan") {
            return "For billing and plan questions, I can help you right away. What specific information do you need about your account?"
        } else {
            return "Thanks for reaching out! I'll be happy to help you with that. Can you provide a bit more detail about the issue you're experiencing?"
        }
    }
}

struct ChatMessage: Identifiable {
    let id: UUID
    let text: String
    let isFromUser: Bool
    let timestamp: Date
}

struct ChatStatusBar: View {
    let isConnected: Bool
    let isConnecting: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(isConnected ? Color.green : (isConnecting ? Color.orange : Color.gray))
                .frame(width: 8, height: 8)
            
            Text(isConnected ? "Connected" : (isConnecting ? "Connecting..." : "Disconnected"))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if isConnected {
                Text("Sarah - Support Agent")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

struct ChatMessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isFromUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(DateFormatter.timeOnly.string(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity * 0.7, alignment: message.isFromUser ? .trailing : .leading)
            
            if !message.isFromUser {
                Spacer()
            }
        }
    }
}

struct ChatInputBar: View {
    @Binding var message: String
    let onSend: () -> Void
    
    var body: some View {
        HStack {
            TextField("Type a message...", text: $message)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSend()
                }
            
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(18)
            }
            .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

#Preview {
    CustomerSupportView()
}
