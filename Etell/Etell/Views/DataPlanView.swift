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
    @Environment(\.dismiss) private var dismiss
    
    let plans = [
        DataPlan(id: "1", name: "Home 100GB", provider: "Etell", speed: "50 Mbps", dataLimit: "100 GB", price: 1499, features: ["Free router included", "24/7 customer support", "Unlimited night browsing"], isPopular: false),
        DataPlan(id: "2", name: "Basic", provider: "Etell", speed: "25 Mbps", dataLimit: "40 GB", price: 499, features: ["No contract", "Email support"], isPopular: false),
        DataPlan(id: "3", name: "Premium", provider: "Etell", speed: "100 Mbps", dataLimit: "200 GB", price: 2499, features: ["Free router included", "24/7 priority support", "Unlimited night browsing", "Free static IP address"], isPopular: true)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Filter and Sort Header
                    FilterSortHeader()
                    
                    // Plan Cards
                    ForEach(plans) { plan in
                        PlanCard(plan: plan, isCurrentPlan: plan.id == "1") {
                            selectedPlan = plan
                            showingPlanDetails = true
                        }
                    }
                    
                    Spacer(minLength: 100) // Space for tab bar
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .navigationTitle("Select a Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

struct FilterSortHeader: View {
    var body: some View {
        HStack {
            HStack(spacing: 16) {
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("Filter")
                            .font(.subheadline)
                            .foregroundColor(.black)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.black)
                    }
                }
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("Sort")
                            .font(.subheadline)
                            .foregroundColor(.black)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(.black)
                    }
                }
            }
            
            Spacer()
            
            Text("3 plans available")
                .font(.subheadline)
                .foregroundColor(.blue)
        }
    }
}

struct PlanCard: View {
    let plan: DataPlan
    let isCurrentPlan: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with plan name, price and active badge
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "wifi")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(plan.speed) / \(plan.dataLimit)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if isCurrentPlan {
                        Text("Active")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Text("LKR \(Int(plan.price))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("per month")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Features with checkmarks
            VStack(alignment: .leading, spacing: 8) {
                ForEach(plan.features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(.black)
                        Spacer()
                    }
                }
            }
            
            // Currently Active banner or Subscribe button
            if isCurrentPlan {
                Text("Currently Active")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            } else {
                Button(action: onTap) {
                    Text("Subscribe")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentPlan ? Color.blue : Color.gray.opacity(0.2), lineWidth: isCurrentPlan ? 2 : 1)
        )
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
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
                        Text("Subscribe to This Plan")
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
                Text("Are you sure you want to subscribe to the \(plan.name) for LKR \(Int(plan.price))/month?")
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
                    Text("LKR \(Int(plan.price))")
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
        case "Basic":
            return ["WiFi hotspot access", "Email support", "Basic security"]
        case "Premium":
            return ["WiFi hotspot access", "Phone & email support", "Advanced security", "Parental controls"]
        case "Home 100GB":
            return ["Unlimited WiFi hotspot", "24/7 phone support", "Premium security suite", "Advanced parental controls"]
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
