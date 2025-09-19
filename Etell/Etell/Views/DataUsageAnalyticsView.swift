import SwiftUI

struct DataUsageAnalyticsView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingAddonsData = false
    @State private var showingDataPlan = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Modern Background
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
                    VStack(spacing: 24) {
                        // Current Plan Overview
                        CurrentPlanSection(viewModel: viewModel)
                        
                        // Usage Breakdown
                        UsageBreakdownSection(viewModel: viewModel)
                        
                        // Addons Data Usage
                        AddonsDataSection(
                            viewModel: viewModel,
                            showingAddonsData: $showingAddonsData
                        )
                        
                        // Action Buttons
                        ActionButtonsSection(
                            showingAddonsData: $showingAddonsData,
                            showingDataPlan: $showingDataPlan
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Data Usage Analytics")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: $showingAddonsData) {
            AddonsDataView()
        }
        .sheet(isPresented: $showingDataPlan) {
            DataPlanView()
        }
    }
}

// MARK: - Current Plan Section

struct CurrentPlanSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Plan Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Plan")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text("Home 100GB Plan")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Plan Status Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Active")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.green.opacity(0.1), in: Capsule())
            }
            
            // Main Usage Display
            VStack(spacing: 16) {
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: 12)
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .trim(from: 0, to: viewModel.dataUsagePercentage)
                        .stroke(
                            LinearGradient(
                                colors: usageGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: viewModel.dataUsagePercentage)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(viewModel.currentDataUsage))GB")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Text("of \(Int(viewModel.dataLimit))GB")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        Text("\(Int(viewModel.dataUsagePercentage * 100))% used")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                    }
                }
                
                // Plan Details Grid
                HStack(spacing: 20) {
                    PlanDetailCard(
                        title: "Remaining",
                        value: "\(Int(viewModel.dataLimit - viewModel.currentDataUsage))GB",
                        icon: "arrow.down.circle",
                        color: .blue
                    )
                    
                    PlanDetailCard(
                        title: "Days Left",
                        value: "10",
                        icon: "calendar",
                        color: .orange
                    )
                    
                    PlanDetailCard(
                        title: "Renewal",
                        value: "Nov 23",
                        icon: "arrow.clockwise",
                        color: .green
                    )
                }
            }
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
    }
    
    private var usageGradientColors: [Color] {
        let percentage = viewModel.dataUsagePercentage
        if percentage < 0.5 {
            return [.green, .mint]
        } else if percentage < 0.8 {
            return [.yellow, .orange]
        } else {
            return [.orange, .red]
        }
    }
}

struct PlanDetailCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Usage Breakdown Section

struct UsageBreakdownSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Usage Breakdown")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 12) {
                UsageBreakdownRow(
                    category: "Streaming",
                    usage: 45.2,
                    color: .purple,
                    icon: "tv"
                )
                
                UsageBreakdownRow(
                    category: "Gaming",
                    usage: 28.7,
                    color: .blue,
                    icon: "gamecontroller"
                )
                
                UsageBreakdownRow(
                    category: "Browsing",
                    usage: 15.3,
                    color: .green,
                    icon: "safari"
                )
                
                UsageBreakdownRow(
                    category: "Social Media",
                    usage: 8.9,
                    color: .pink,
                    icon: "heart"
                )
                
                UsageBreakdownRow(
                    category: "Other",
                    usage: 1.9,
                    color: .gray,
                    icon: "ellipsis"
                )
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 0.5)
        )
    }
}

struct UsageBreakdownRow: View {
    let category: String
    let usage: Double
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 20, height: 20)
            
            Text(category)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text("\(usage, specifier: "%.1f")GB")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Addons Data Section

struct AddonsDataSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var showingAddonsData: Bool
    
    private let addonsData = [
        AddonData(name: "Video Streaming Pack", usage: 8.5, limit: 20.0, isActive: true),
        AddonData(name: "Gaming Boost", usage: 12.3, limit: 15.0, isActive: true),
        AddonData(name: "Social Media Bundle", usage: 0.0, limit: 5.0, isActive: false)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Addon Data Packages")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button(action: {
                    showingAddonsData = true
                }) {
                    Text("Manage")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.blue)
                }
            }
            
            if addonsData.filter({ $0.isActive }).isEmpty {
                AddonEmptyState(showingAddonsData: $showingAddonsData)
            } else {
                VStack(spacing: 12) {
                    ForEach(addonsData.filter { $0.isActive }, id: \.name) { addon in
                        AddonDataCard(addon: addon)
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 0.5)
        )
    }
}

struct AddonData {
    let name: String
    let usage: Double
    let limit: Double
    let isActive: Bool
    
    var usagePercentage: Double {
        guard limit > 0 else { return 0 }
        return min(usage / limit, 1.0)
    }
}

struct AddonDataCard: View {
    let addon: AddonData
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(addon.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("\(addon.usage, specifier: "%.1f")GB of \(addon.limit, specifier: "%.0f")GB")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(addon.usagePercentage * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                
                ProgressView(value: addon.usagePercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: addon.usagePercentage > 0.8 ? .red : .blue))
                    .frame(width: 60)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary, lineWidth: 0.5)
        )
    }
}

struct AddonEmptyState: View {
    @Binding var showingAddonsData: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(.blue)
            
            Text("No Active Addons")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
            
            Text("Add data packages to enhance your plan")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingAddonsData = true
            }) {
                Text("Browse Addons")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.blue.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Action Buttons Section

struct ActionButtonsSection: View {
    @Binding var showingAddonsData: Bool
    @Binding var showingDataPlan: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Add Addon Data Button
            Button(action: {
                showingAddonsData = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                    
                    Text("Add Addon Data")
                        .font(.system(size: 17, weight: .semibold))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            
            // Change WiFi Package Button
            Button(action: {
                showingDataPlan = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                    
                    Text("Change WiFi Package")
                        .font(.system(size: 17, weight: .semibold))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.blue.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Placeholder Views

struct AddonsDataView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Addons Data Packages")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Text("This is where addon data packages would be displayed.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Addon Data")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                dismiss()
            }
        }
    }
}

extension View {
    func navigationBarCloseButton(action: @escaping () -> Void) -> some View {
        self.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    action()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        DataUsageAnalyticsView()
            .environmentObject(DashboardViewModel())
    }
}
