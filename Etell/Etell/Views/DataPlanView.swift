//
//  DataPlanView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI

struct DataPlanView: View {
    @State private var selectedPlan: DataPlan?
    @State private var showingPlanDetails = false
    
    let plans = DataPlan.mockPlans
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    PlanSelectionHeader()
                    
                    // Plans Grid
                    ForEach(plans) { plan in
                        PlanCard(plan: plan, isSelected: selectedPlan?.id == plan.id) {
                            selectedPlan = plan
                            showingPlanDetails = true
                        }
                    }
                    
                    // Current Plan Status
                    CurrentPlanStatus()
                }
                .padding()
            }
            .navigationTitle("Data Plans")
            .sheet(isPresented: $showingPlanDetails) {
                if let plan = selectedPlan {
                    PlanDetailView(plan: plan)
                }
            }
        }
    }
}

struct PlanSelectionHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose Your Perfect Plan")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Select a data plan that fits your needs. All plans include unlimited calling and flexible terms.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PlanCard: View {
    let plan: DataPlan
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with Popular Badge
                HStack {
                    VStack(alignment: .leading) {
                        Text(plan.name)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(plan.provider)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if plan.isPopular {
                        Text("POPULAR")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                // Speed and Data
                HStack {
                    InfoItem(title: "Speed", value: plan.speed, icon: "speedometer")
                    Spacer()
                    InfoItem(title: "Data", value: plan.dataLimit, icon: "chart.bar.fill")
                }
                
                // Features
                VStack(alignment: .leading, spacing: 4) {
                    Text("Features:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(plan.features, id: \.self) { feature in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(feature)
                                .font(.caption)
                        }
                    }
                }
                
                // Price
                HStack {
                    Text("$\(plan.price, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("/month")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Select Plan")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(plan.isPopular ? Color.orange : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
    }
}

struct CurrentPlanStatus: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Plan")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Premium Plan")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("100 Mbps • 500 GB")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("$59.99/mo")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Renews Jan 15")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Button("Modify Plan") {
                    // Handle plan modification
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("Cancel Plan") {
                    // Handle plan cancellation
                }
                .font(.subheadline)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PlanDetailView: View {
    let plan: DataPlan
    @Environment(\.dismiss) var dismiss
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Plan Overview
                    PlanOverviewSection(plan: plan)
                    
                    // Detailed Features
                    PlanFeaturesSection(plan: plan)
                    
                    // Terms and Conditions
                    TermsSection()
                    
                    // Action Button
                    Button(action: {
                        showingConfirmation = true
                    }) {
                        Text("Select This Plan")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle(plan.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Confirm Plan Selection", isPresented: $showingConfirmation) {
                Button("Confirm") {
                    // Handle plan selection
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to select the \(plan.name) for $\(plan.price, specifier: "%.2f")/month?")
            }
        }
    }
}

struct PlanOverviewSection: View {
    let plan: DataPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(plan.name)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(plan.provider)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if plan.isPopular {
                    Text("MOST POPULAR")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
            
            HStack(spacing: 30) {
                VStack {
                    Text(plan.speed)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Speed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text(plan.dataLimit)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("$\(plan.price, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("per month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PlanFeaturesSection: View {
    let plan: DataPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's Included")
                .font(.headline)
            
            ForEach(plan.features, id: \.self) { feature in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(feature)
                        .font(.subheadline)
                    Spacer()
                }
            }
            
            // Additional mock features based on plan type
            ForEach(additionalFeatures, id: \.self) { feature in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(feature)
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var additionalFeatures: [String] {
        switch plan.name {
        case "Basic Plan":
            return ["WiFi hotspot access", "Email support", "Basic security"]
        case "Premium Plan":
            return ["WiFi hotspot access", "Phone & email support", "Advanced security", "Parental controls"]
        case "Ultimate Plan":
            return ["Unlimited WiFi hotspot", "24/7 phone support", "Premium security suite", "Advanced parental controls", "Static IP address"]
        default:
            return []
        }
    }
}

struct TermsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Terms & Conditions")
                .font(.headline)
            
            Text("• No long-term contracts required")
            Text("• 30-day money-back guarantee")
            Text("• Free installation and setup")
            Text("• Cancel anytime with 30 days notice")
            Text("• Fair usage policy applies")
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    DataPlanView()
}
