//
//  CustomerSupportView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI
import UIKit

struct CustomerSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingFAQ = false
    @State private var showingLiveChat = false
    @State private var showingIssueReport = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Support Icon
                    VStack(spacing: 16) {
                        Image(systemName: "headphones")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .frame(width: 100, height: 100)
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Circle())
                        
                        VStack(spacing: 8) {
                            Text("We're here to help! Choose an option below")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Text("to get the support you need.")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Support Options
                    VStack(spacing: 16) {
                        SupportOptionCard(
                            icon: "questionmark.circle.fill",
                            iconColor: .blue,
                            title: "FAQs",
                            subtitle: "Browse common questions",
                            action: {
                                showingFAQ = true
                            }
                        )
                        
                        SupportOptionCard(
                            icon: "message.circle.fill",
                            iconColor: .green,
                            title: "Live Chat",
                            subtitle: "Chat with our support team",
                            action: {
                                showingLiveChat = true
                            }
                        )
                        
                        SupportOptionCard(
                            icon: "exclamationmark.triangle.fill",
                            iconColor: .red,
                            title: "Report Issue",
                            subtitle: "Report a technical problem",
                            action: {
                                showingIssueReport = true
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Contact Us Directly
                    VStack(spacing: 16) {
                        Text("Contact Us Directly")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top, 20)
                        
                        HStack(spacing: 16) {
                            ContactDirectButton(
                                icon: "phone.fill",
                                title: "Call Us",
                                subtitle: "1800 ETELL 24",
                                color: .blue,
                                action: {
                                    if let url = URL(string: "tel:1800ETELL24") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                            
                            ContactDirectButton(
                                icon: "envelope.fill",
                                title: "Email",
                                subtitle: "support@etell.com",
                                color: .orange,
                                action: {
                                    if let url = URL(string: "mailto:support@etell.com") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Customer Support")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingFAQ) {
            FAQView()
        }
        .sheet(isPresented: $showingLiveChat) {
            LiveChatView()
        }
        .sheet(isPresented: $showingIssueReport) {
            IssueReportView()
        }
    }
}

// MARK: - Support Components

struct SupportOptionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContactDirectButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .clipShape(Circle())
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Support Views

struct FAQView: View {
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
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search FAQs...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                // FAQ List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredFAQs) { faq in
                            FAQItem(
                                faq: faq,
                                isExpanded: expandedItems.contains(faq.id),
                                onTap: {
                                    if expandedItems.contains(faq.id) {
                                        expandedItems.remove(faq.id)
                                    } else {
                                        expandedItems.insert(faq.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
                
                Spacer()
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

struct FAQItem: View {
    let faq: FAQ
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Text(faq.question)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(faq.answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.secondarySystemBackground))
            }
        }
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct LiveChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(content: "Hello! How can I help you today?", isFromUser: false, timestamp: Date())
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollViewReader { scrollViewReader in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { oldValue, newValue in
                        if let lastMessage = messages.last {
                            withAnimation {
                                scrollViewReader.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Message Input
                HStack {
                    TextField("Type your message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Send") {
                        sendMessage()
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Live Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        let userMessage = ChatMessage(content: trimmedMessage, isFromUser: true, timestamp: Date())
        messages.append(userMessage)
        messageText = ""
        
        // Simulate response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let response = generateResponse(to: trimmedMessage)
            let botMessage = ChatMessage(content: response, isFromUser: false, timestamp: Date())
            messages.append(botMessage)
        }
    }
    
    private func generateResponse(to message: String) -> String {
        let responses = [
            "Thank you for contacting us. I'm looking into your query.",
            "I understand your concern. Let me help you with that.",
            "That's a great question! Here's what I can tell you...",
            "I'm connecting you with a specialist who can better assist you.",
            "Thank you for your patience. I'll have an answer for you shortly."
        ]
        return responses.randomElement() ?? "Thank you for your message."
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 60)
                
                Text(message.content)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Support Agent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(message.content)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(16)
                }
                .frame(maxWidth: .infinity * 0.7, alignment: .leading)
                
                Spacer(minLength: 60)
            }
        }
    }
}

struct IssueReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var issueType = "Technical Issue"
    @State private var priority = "Medium"
    @State private var contactName = ""
    @State private var contactEmail = ""
    @State private var issueDescription = ""
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    
    let issueTypes = ["Technical Issue", "Billing Problem", "Service Outage", "Account Issue", "Feature Request"]
    let priorities = ["Low", "Medium", "High", "Critical"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Issue Details") {
                    Picker("Issue Type", selection: $issueType) {
                        ForEach(issueTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.self) { priority in
                            Text(priority).tag(priority)
                        }
                    }
                }
                
                Section("Contact Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.headline)
                        
                        TextField("Your full name", text: $contactName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contact Email")
                            .font(.headline)
                        
                        TextField("your.email@example.com", text: $contactEmail)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Issue Description")
                            .font(.headline)
                        
                        TextEditor(text: $issueDescription)
                            .frame(minHeight: 100)
                            .padding(4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                Section {
                    Button(action: submitReport) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            
                            Text(isSubmitting ? "Submitting..." : "Submit Report")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isSubmitting || contactName.isEmpty || contactEmail.isEmpty || issueDescription.isEmpty)
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
            .alert("Report Submitted", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your issue report has been submitted successfully. We'll get back to you within 24 hours.")
            }
        }
    }
    
    private func submitReport() {
        isSubmitting = true
        
        // Simulate form submission
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSubmitting = false
            showingSuccess = true
        }
    }
}

// MARK: - Data Models

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

#Preview {
    CustomerSupportView()
}
