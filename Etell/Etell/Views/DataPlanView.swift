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
    @State private var showingFilters = false
    @State private var showingAddPlan = false
    @State private var sortOption: SortOption = .price
    @State private var filterOption: FilterOption = .all
    @State private var currentPlanId: String = "1"
    @Environment(\.dismiss) private var dismiss
    
    @State private var plans = [
        DataPlan(id: "1", name: "Home 100GB", provider: "Etell", speed: "50 Mbps", dataLimit: "100 GB", price: 1499, features: ["Free router included", "24/7 customer support", "Unlimited night browsing"], isPopular: false),
        DataPlan(id: "2", name: "Basic", provider: "Etell", speed: "25 Mbps", dataLimit: "40 GB", price: 499, features: ["No contract", "Email support"], isPopular: false),
        DataPlan(id: "3", name: "Premium", provider: "Etell", speed: "100 Mbps", dataLimit: "200 GB", price: 2499, features: ["Free router included", "24/7 priority support", "Unlimited night browsing", "Free static IP address"], isPopular: true),
        DataPlan(id: "4", name: "Ultra", provider: "Etell", speed: "200 Mbps", dataLimit: "500 GB", price: 3999, features: ["Free router included", "24/7 priority support", "Unlimited night browsing", "Free static IP address", "Gaming optimization"], isPopular: false),
        DataPlan(id: "5", name: "Business", provider: "Etell", speed: "150 Mbps", dataLimit: "Unlimited", price: 5999, features: ["Dedicated support", "Business SLA", "Static IP included", "Priority routing"], isPopular: false),
        DataPlan(id: "6", name: "Student", provider: "Etell", speed: "30 Mbps", dataLimit: "50 GB", price: 799, features: ["Student discount", "Email support", "Educational content access"], isPopular: false),
        DataPlan(id: "7", name: "Family", provider: "Etell", speed: "75 Mbps", dataLimit: "300 GB", price: 1999, features: ["Multiple device support", "Parental controls", "Family sharing", "24/7 support"], isPopular: true),
        DataPlan(id: "8", name: "Gamer Pro", provider: "Etell", speed: "300 Mbps", dataLimit: "1 TB", price: 4999, features: ["Ultra-low latency", "Gaming servers", "DDoS protection", "Priority gaming traffic"], isPopular: false),
        DataPlan(id: "9", name: "Starter", provider: "Etell", speed: "15 Mbps", dataLimit: "20 GB", price: 299, features: ["Budget-friendly", "Basic support", "Email only"], isPopular: false),
        DataPlan(id: "10", name: "Enterprise", provider: "Etell", speed: "500 Mbps", dataLimit: "Unlimited", price: 9999, features: ["Enterprise SLA", "Dedicated account manager", "Custom solutions", "99.9% uptime guarantee"], isPopular: false),
        DataPlan(id: "11", name: "Senior Citizen", provider: "Etell", speed: "40 Mbps", dataLimit: "80 GB", price: 999, features: ["Senior discount", "Easy setup", "24/7 phone support", "Simple billing"], isPopular: false),
        DataPlan(id: "12", name: "Work From Home", provider: "Etell", speed: "120 Mbps", dataLimit: "400 GB", price: 2799, features: ["Video conferencing optimized", "VPN support", "Cloud storage", "Business hours priority"], isPopular: true),
        DataPlan(id: "13", name: "Streaming Plus", provider: "Etell", speed: "80 Mbps", dataLimit: "250 GB", price: 1799, features: ["4K streaming optimized", "Netflix included", "No throttling", "Multiple screens"], isPopular: false),
        DataPlan(id: "14", name: "Mobile Hotspot", provider: "Etell", speed: "60 Mbps", dataLimit: "150 GB", price: 1299, features: ["Portable router", "Multi-device sharing", "Travel-friendly", "No installation"], isPopular: false),
        DataPlan(id: "15", name: "Night Owl", provider: "Etell", speed: "45 Mbps", dataLimit: "Unlimited", price: 1599, features: ["Unlimited night data", "Peak hour limits", "Perfect for downloads", "Late night streaming"], isPopular: false)
    ]
    
    enum SortOption: String, CaseIterable {
        case price = "Price"
        case speed = "Speed"
        case data = "Data Limit"
        case name = "Name"
        
        var systemImage: String {
            switch self {
            case .price: return "dollarsign.circle"
            case .speed: return "speedometer"
            case .data: return "internaldrive"
            case .name: return "textformat.abc"
            }
        }
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All Plans"
        case popular = "Popular"
        case highSpeed = "High Speed"
        case unlimited = "Unlimited"
        case budget = "Budget"
        
        var systemImage: String {
            switch self {
            case .all: return "list.bullet"
            case .popular: return "star.fill"
            case .highSpeed: return "bolt.fill"
            case .unlimited: return "infinity"
            case .budget: return "creditcard"
            }
        }
    }
    
    var filteredAndSortedPlans: [DataPlan] {
        let filtered = filterPlans(plans)
        return sortPlans(filtered)
    }
    
    private func filterPlans(_ plans: [DataPlan]) -> [DataPlan] {
        switch filterOption {
        case .all:
            return plans
        case .popular:
            return plans.filter { $0.isPopular }
        case .highSpeed:
            return plans.filter { extractSpeedValue($0.speed) >= 100 }
        case .unlimited:
            return plans.filter { $0.dataLimit.lowercased().contains("unlimited") }
        case .budget:
            return plans.filter { $0.price <= 1000 }
        }
    }
    
    private func sortPlans(_ plans: [DataPlan]) -> [DataPlan] {
        switch sortOption {
        case .price:
            return plans.sorted { $0.price < $1.price }
        case .speed:
            return plans.sorted { extractSpeedValue($0.speed) > extractSpeedValue($1.speed) }
        case .data:
            return plans.sorted { extractDataValue($0.dataLimit) > extractDataValue($1.dataLimit) }
        case .name:
            return plans.sorted { $0.name < $1.name }
        }
    }
    
    private func extractSpeedValue(_ speed: String) -> Int {
        let numbers = speed.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(numbers) ?? 0
    }
    
    private func extractDataValue(_ dataLimit: String) -> Int {
        if dataLimit.lowercased().contains("unlimited") {
            return Int.max
        }
        let numbers = dataLimit.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(numbers) ?? 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header Section
                    EnhancedHeaderSection(planCount: filteredAndSortedPlans.count)
                    
                    // Filter and Sort Section
                    EnhancedFilterSortSection(
                        sortOption: $sortOption,
                        filterOption: $filterOption,
                        showingFilters: $showingFilters
                    )
                    
                    // Plan Cards
                    ForEach(filteredAndSortedPlans) { plan in
                        ModernPlanCard(
                            plan: plan,
                            isCurrentPlan: plan.id == currentPlanId
                        ) {
                            handlePlanSelection(plan)
                        }
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Data Plans")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.caption.weight(.semibold))
                            Text("Back")
                                .font(.body)
                        }
                        .foregroundStyle(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(item: $selectedPlan) { plan in
                ModernPlanDetailView(plan: plan)
            }
            .sheet(isPresented: $showingFilters) {
                FilterSortOptionsView(
                    sortOption: $sortOption,
                    filterOption: $filterOption
                )
            }
            .sheet(isPresented: $showingAddPlan) {
                AddNewPlanView { newPlan in
                    plans.append(newPlan)
                }
            }
        }
    }
    
    private func handlePlanSelection(_ plan: DataPlan) {
        if plan.id != currentPlanId {
            // Show plan details for subscription
            selectedPlan = plan
            showingPlanDetails = true
        } else {
            // Show current plan details
            selectedPlan = plan
            showingPlanDetails = true
        }
    }
}

// MARK: - Header Section
struct HeaderSection: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose Your Plan")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Select the perfect data plan for your needs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Filter and Sort Section
struct FilterSortSection: View {
    @Binding var showingFilters: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 16) {
                FilterButton(title: "All Plans", isSelected: true)
                FilterButton(title: "Popular", isSelected: false)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("3 plans")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                
                Text("available")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Button(action: {}) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? .blue : .blue.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Plan Card
struct ModernPlanCard: View {
    let plan: DataPlan
    let isCurrentPlan: Bool
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 0) {
            popularBadge
            VStack(spacing: 20) {
                headerSection
                featuresGrid
                actionButton
            }
            .padding(24)
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            plan.isPopular ? .blue.opacity(0.3) : .clear,
                            lineWidth: 2
                        )
                }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            if !isCurrentPlan {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                    onTap()
                }
            }
        }
    }

    private var popularBadge: some View {
        Group {
            if plan.isPopular {
                HStack {
                    Spacer()
                    Text("MOST POPULAR")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    Spacer()
                }
                .padding(.bottom, 16)
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(plan.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                HStack(spacing: 6) {
                    Image(systemName: "wifi")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text("\(plan.speed) • \(plan.dataLimit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if isCurrentPlan {
                    Text("Current Plan")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.green, in: Capsule())
                }
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("LKR")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(plan.price))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                Text("per month")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var featuresGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 1), spacing: 12) {
            ForEach(plan.features, id: \.self) { feature in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text(feature)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
        }
    }

    private var actionButton: some View {
        Button(action: onTap) {
            HStack {
                if isCurrentPlan {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Current Plan")
                        .fontWeight(.semibold)
                } else {
                    Text("Choose Plan")
                        .fontWeight(.semibold)
                }
            }
            .font(.subheadline)
            .foregroundColor(isCurrentPlan ? .secondary : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                isCurrentPlan ? Color.clear : Color.blue
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCurrentPlan ? .secondary : Color.clear, lineWidth: 1)
            )
        }
        .disabled(isCurrentPlan)
        .buttonStyle(.plain)
    }
}
// MARK: - Modern Plan Detail View
struct ModernPlanDetailView: View {
    let plan: DataPlan
    @Environment(\.dismiss) var dismiss
    @State private var showingConfirmation = false
    @State private var isSubscribing = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Hero Section
                    PlanHeroSection(plan: plan)
                    
                    // Speed & Data Section
                    SpeedDataSection(plan: plan)
                    
                    // Features Section
                    ModernFeaturesSection(plan: plan)
                    
                    // Terms Section
                    ModernTermsSection()
                    
                    // Subscribe Button
                    VStack(spacing: 16) {
                        Button {
                            showingConfirmation = true
                        } label: {
                            HStack {
                                if isSubscribing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Subscribe to \(plan.name)")
                                        .fontWeight(.semibold)
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                        }
                        .disabled(isSubscribing)
                        .buttonStyle(.plain)
                        
                        Text("30-day money-back guarantee")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(plan.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            }
            .alert("Confirm Subscription", isPresented: $showingConfirmation) {
                Button("Subscribe") {
                    handleSubscription()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Subscribe to \(plan.name) for LKR \(Int(plan.price))/month?")
            }
        }
    }
    
    private func handleSubscription() {
        isSubscribing = true
        
        // Simulate subscription process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSubscribing = false
            dismiss()
        }
    }
}

// MARK: - Plan Hero Section
struct PlanHeroSection: View {
    let plan: DataPlan
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(plan.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        if plan.isPopular {
                            Text("POPULAR")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.orange, in: Capsule())
                        }
                    }
                    
                    Text("by \(plan.provider)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 0) {
                Text("LKR ")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Text("\(Int(plan.price))")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                
                Text("/month")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Speed & Data Section
struct SpeedDataSection: View {
    let plan: DataPlan
    
    var body: some View {
        HStack(spacing: 20) {
            MetricCard(
                icon: "speedometer",
                title: "Speed",
                value: plan.speed,
                color: .blue
            )
            
            MetricCard(
                icon: "internaldrive",
                title: "Data",
                value: plan.dataLimit,
                color: .green
            )
        }
    }
}

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Modern Features Section
struct ModernFeaturesSection: View {
    let plan: DataPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's Included")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                ForEach(allFeatures, id: \.self) { feature in
                    PlanFeatureRow(feature: feature)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var allFeatures: [String] {
        var features = plan.features
        
        // Add plan-specific features
        switch plan.name {
        case "Basic":
            features.append(contentsOf: ["WiFi hotspot access", "Basic security"])
        case "Premium":
            features.append(contentsOf: ["WiFi hotspot access", "Advanced security", "Parental controls"])
        case "Home 100GB":
            features.append(contentsOf: ["Unlimited WiFi hotspot", "Premium security suite", "Advanced parental controls"])
        default:
            break
        }
        
        return features
    }
}

struct PlanFeatureRow: View {
    let feature: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.green)
            
            Text(feature)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Modern Terms Section
struct ModernTermsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Terms & Benefits")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            VStack(spacing: 10) {
                TermRow(icon: "checkmark.shield", text: "30-day money-back guarantee")
                TermRow(icon: "wifi", text: "Free installation and setup")
                TermRow(icon: "clock", text: "Cancel anytime with 30 days notice")
                TermRow(icon: "doc.text", text: "No long-term contracts required")
                TermRow(icon: "chart.bar", text: "Fair usage policy applies")
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct TermRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Plan Filter Options View
struct PlanFilterOptionsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Filter options coming soon...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Enhanced Header Section
struct EnhancedHeaderSection: View {
    let planCount: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose Your Plan")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Select the perfect data plan for your needs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(planCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    
                    Text("plans available")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Enhanced Filter and Sort Section
struct EnhancedFilterSortSection: View {
    @Binding var sortOption: DataPlanView.SortOption
    @Binding var filterOption: DataPlanView.FilterOption
    @Binding var showingFilters: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Filter Button
            Button {
                showingFilters = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: filterOption.systemImage)
                        .font(.caption)
                    Text(filterOption.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(filterOption == .all ? .blue : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(filterOption == .all ? .blue.opacity(0.1) : .blue)
                )
            }
            .buttonStyle(.plain)
            
            // Sort Button
            Button {
                // Cycle through sort options
                if let currentIndex = DataPlanView.SortOption.allCases.firstIndex(of: sortOption) {
                    let nextIndex = (currentIndex + 1) % DataPlanView.SortOption.allCases.count
                    sortOption = DataPlanView.SortOption.allCases[nextIndex]
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: sortOption.systemImage)
                        .font(.caption)
                    Text("Sort by \(sortOption.rawValue)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.blue.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Add New Plan Button
struct AddNewPlanButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add New Plan")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("Create a custom data plan")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.blue.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Sort Options View
struct FilterSortOptionsView: View {
    @Binding var sortOption: DataPlanView.SortOption
    @Binding var filterOption: DataPlanView.FilterOption
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Filter Plans") {
                    ForEach(DataPlanView.FilterOption.allCases, id: \.self) { option in
                        Button {
                            filterOption = option
                        } label: {
                            HStack {
                                Image(systemName: option.systemImage)
                                    .foregroundStyle(.blue)
                                    .frame(width: 24)
                                
                                Text(option.rawValue)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if filterOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Section("Sort Plans") {
                    ForEach(DataPlanView.SortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack {
                                Image(systemName: option.systemImage)
                                    .foregroundStyle(.blue)
                                    .frame(width: 24)
                                
                                Text(option.rawValue)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Add New Plan View
struct AddNewPlanView: View {
    @Environment(\.dismiss) var dismiss
    let onPlanAdded: (DataPlan) -> Void
    
    @State private var planName = ""
    @State private var planSpeed = ""
    @State private var planDataLimit = ""
    @State private var planPrice = ""
    @State private var planFeatures: [String] = []
    @State private var newFeature = ""
    @State private var isPopular = false
    
    var isFormValid: Bool {
        !planName.isEmpty &&
        !planSpeed.isEmpty &&
        !planDataLimit.isEmpty &&
        !planPrice.isEmpty &&
        Double(planPrice) != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Plan Details") {
                    TextField("Plan Name", text: $planName)
                    TextField("Speed (e.g., 100 Mbps)", text: $planSpeed)
                    TextField("Data Limit (e.g., 200 GB)", text: $planDataLimit)
                    TextField("Price (LKR)", text: $planPrice)
                        .keyboardType(.decimalPad)
                }
                
                Section("Features") {
                    ForEach(planFeatures.indices, id: \.self) { index in
                        HStack {
                            Text(planFeatures[index])
                            Spacer()
                            Button("Remove") {
                                planFeatures.remove(at: index)
                            }
                            .foregroundStyle(.red)
                        }
                    }
                    
                    HStack {
                        TextField("Add feature", text: $newFeature)
                        Button("Add") {
                            if !newFeature.isEmpty {
                                planFeatures.append(newFeature)
                                newFeature = ""
                            }
                        }
                        .disabled(newFeature.isEmpty)
                    }
                }
                
                Section("Options") {
                    Toggle("Mark as Popular", isOn: $isPopular)
                }
                
                Section {
                    Button("Create Plan") {
                        createPlan()
                    }
                    .disabled(!isFormValid)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(isFormValid ? .blue : .secondary)
                }
            }
            .navigationTitle("Add New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createPlan() {
        guard let price = Double(planPrice) else { return }
        
        let newPlan = DataPlan(
            id: UUID().uuidString,
            name: planName,
            provider: "Etell",
            speed: planSpeed,
            dataLimit: planDataLimit,
            price: price,
            features: planFeatures,
            isPopular: isPopular
        )
        
        onPlanAdded(newPlan)
        dismiss()
    }
}

#Preview {
    DataPlanView()
}
