//
//  DashboardView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @State private var refreshing = false
    @State private var lastRefreshed = Date()
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 24) {
                    // Status Bar and Welcome Header
                    VStack(spacing: 16) {
                        LastRefreshedBar(lastRefreshed: lastRefreshed)
                        WelcomeHeader()
                    }
                    .padding(.top, 8)
                    
                    // Primary Action - AR Calibration Card
                    ARCalibrationCard()
                    
                    // Data Usage Overview
                    DataUsageOverviewCard()
                    
                    // Quick Actions Grid
                    QuickActionsGrid()
                    
                    Spacer(minLength: 100) // Space for tab bar
                }
                .padding(.horizontal, 20)
                .refreshable {
                    await refreshDashboard()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
    
    private func refreshDashboard() async {
        refreshing = true
        viewModel.refreshData()
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        refreshing = false
        lastRefreshed = Date()
    }
}

// MARK: - Last Refreshed Bar
struct LastRefreshedBar: View {
    let lastRefreshed: Date
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("Last refreshed:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(timeAgoText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(lastRefreshed, style: .time)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(.horizontal, 4)
    }
    
    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastRefreshed, relativeTo: Date())
    }
}

struct WelcomeHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hi Geeneth")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Your network is performing well")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundStyle(.blue.gradient)
                    .background(.white, in: Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct ARCalibrationCard: View {
    @State private var showingSetupQuestionnaire = false
    @State private var showingSensorCalibration = false
    @State private var isPressed = false
    @State private var setupData = CalibrationSetupData()
    
    var body: some View {
        Button(action: {
            // Show questionnaire first
            showingSetupQuestionnaire = true
        }) {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "sensor.tag.radiowaves.forward")
                                .font(.title2)
                                .foregroundStyle(.white)
                            
                            Text("Premium Feature")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.white.opacity(0.2), in: Capsule())
                        }
                        
                        Text("Launch WiFi Calibration")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("Advanced sensor-based optimization using AR technology")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                        Spacer()
                    }
                }
                
                HStack(spacing: 16) {
                    FeaturePill(icon: "sensor", text: "Smart Sensors")
                    FeaturePill(icon: "point.3.connected.trianglepath.dotted", text: "AI Analysis")
                    FeaturePill(icon: "arkit", text: "AR Mapping")
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.blue.opacity(0.8),
                                Color.purple.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .onPressGesture(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .sheet(isPresented: $showingSetupQuestionnaire) {
            WiFiCalibrationQuestionnaire { completedSetupData in
                setupData = completedSetupData
                showingSetupQuestionnaire = false
                
                // Save setup data and proceed to calibration
                CalibrationSetupService.shared.saveSetupData(completedSetupData)
                showingSensorCalibration = true
            }
        }
        .fullScreenCover(isPresented: $showingSensorCalibration) {
            // Use the setup data from questionnaire
            SensorBasedCalibrationView(setupData: setupData)
        }
    }
}

struct FeaturePill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.15), in: Capsule())
    }
}

// MARK: - Data Usage Overview Card
struct DataUsageOverviewCard: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Data Usage")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Home 100GB Plan")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                NavigationLink(destination: DataUsageAnalyticsView()) {
                    Text("View Details")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            
            VStack(spacing: 16) {
                // Usage Stats
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(viewModel.currentDataUsage))GB")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("of \(Int(viewModel.dataLimit))GB used")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("10 days left")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text("Expires Nov 23")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                // Progress Ring
                ProgressRing(
                    progress: viewModel.dataUsagePercentage,
                    color: usageColor,
                    lineWidth: 8
                )
                .frame(height: 12)
                
                // Usage breakdown
                HStack {
                    UsageIndicator(
                        color: usageColor,
                        label: "Used",
                        value: "\(Int(viewModel.currentDataUsage))GB"
                    )
                    
                    Spacer()
                    
                    UsageIndicator(
                        color: .gray.opacity(0.3),
                        label: "Remaining", 
                        value: "\(Int(viewModel.dataLimit - viewModel.currentDataUsage))GB"
                    )
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
    
    private var usageColor: Color {
        switch viewModel.dataUsagePercentage {
        case 0..<0.7: return .green
        case 0.7..<0.9: return .orange
        default: return .red
        }
    }
}

struct ProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background ring
                Capsule()
                    .fill(.quaternary)
                    .frame(height: lineWidth)
                
                // Progress ring
                HStack {
                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(progress), height: lineWidth)
                    
                    Spacer()
                }
            }
        }
    }
}

struct UsageIndicator: View {
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }
}


// MARK: - Quick Actions Grid
struct QuickActionsGrid: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Actions")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Manage your network and services")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "bolt.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue.gradient)
            }
            .padding(.horizontal, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                EnhancedQuickActionCard(
                    icon: "wifi.router",
                    title: "Speed Test",
                    subtitle: "Test your connection speed",
                    primaryColor: .blue,
                    secondaryColor: .cyan,
                    destination: AnyView(SpeedTestView())
                )
                
                EnhancedQuickActionCard(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "Signal Map",
                    subtitle: "View network coverage",
                    primaryColor: .green,
                    secondaryColor: .mint,
                    destination: AnyView(SignalMapView())
                )
                
                EnhancedQuickActionCard(
                    icon: "person.wave.2.fill",
                    title: "Support",
                    subtitle: "Get instant help",
                    primaryColor: .purple,
                    secondaryColor: .indigo,
                    destination: AnyView(CustomerSupportView())
                )
                
                EnhancedQuickActionCard(
                    icon: "bag.circle.fill",
                    title: "Store",
                    subtitle: "Browse accessories",
                    primaryColor: .orange,
                    secondaryColor: .yellow,
                    destination: AnyView(AccessoriesStoreView())
                )
            }
        }
    }
}

struct EnhancedQuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let primaryColor: Color
    let secondaryColor: Color
    let destination: AnyView
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 0) {
                // Icon Section with Gradient Background
                ZStack {
                    // Gradient Background
                    LinearGradient(
                        colors: [primaryColor.opacity(0.8), secondaryColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 80)
                    
                    // Pattern Overlay
                    Image(systemName: "circle.grid.2x2")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.1))
                        .offset(x: 20, y: -10)
                    
                    VStack(spacing: 8) {
                        // Main Icon
                        Image(systemName: icon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        
                        Spacer()
                    }
                    .padding(.top, 28)
                    
                    // Arrow indicator
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.trailing, 12)
                                .padding(.top, 24)
                        }
                        Spacer()
                    }
                }
                
                // Content Section
                VStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: primaryColor.opacity(0.2), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onPressGesture(
            onPress: { 
                withAnimation(.easeIn(duration: 0.1)) {
                    isPressed = true
                }
            },
            onRelease: { 
                withAnimation(.easeOut(duration: 0.2)) {
                    isPressed = false
                }
            }
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Flash Deals Section
struct FlashDealsSection: View {
    @State private var selectedTab = 0
    @State private var timer: Timer?
    
    private let tabs = ["Hot Deals", "Data Plans", "Accessories", "Premium"]
    private let autoScrollInterval: TimeInterval = 3.0
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with moving tabs
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                            
                            Text("Flash Deals")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text("Limited time offers • Auto-updating")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Text("View All")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }
                }
                
                // Auto-moving tabs
                AutoMovingTabs(
                    tabs: tabs,
                    selectedTab: $selectedTab,
                    autoScrollInterval: autoScrollInterval
                )
            }
            
            // Deal cards based on selected tab
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(dealsForCurrentTab, id: \.id) { deal in
                        FlashDealCard(deal: deal)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var dealsForCurrentTab: [FlashDeal] {
        switch selectedTab {
        case 0: return hotDeals
        case 1: return dataPlans
        case 2: return accessories
        case 3: return premiumDeals
        default: return hotDeals
        }
    }
    
    // Sample data for different categories
    private var hotDeals: [FlashDeal] {
        [
            FlashDeal(
                id: "hot1",
                title: "WiFi 6 Router",
                subtitle: "Ultra-fast speeds",
                originalPrice: 299.99,
                dealPrice: 199.99,
                discount: 33,
                timeLeft: "2h 15m",
                icon: "wifi.router",
                color: .red,
                category: .hotDeal
            ),
            FlashDeal(
                id: "hot2",
                title: "Mesh System",
                subtitle: "Whole home coverage",
                originalPrice: 449.99,
                dealPrice: 299.99,
                discount: 33,
                timeLeft: "4h 30m",
                icon: "dot.radiowaves.up.forward",
                color: .orange,
                category: .hotDeal
            )
        ]
    }
    
    private var dataPlans: [FlashDeal] {
        [
            FlashDeal(
                id: "data1",
                title: "Unlimited Pro",
                subtitle: "No speed limits",
                originalPrice: 89.99,
                dealPrice: 59.99,
                discount: 33,
                timeLeft: "1 day",
                icon: "infinity.circle",
                color: .blue,
                category: .dataPlan
            ),
            FlashDeal(
                id: "data2",
                title: "Family Pack",
                subtitle: "5 devices included",
                originalPrice: 129.99,
                dealPrice: 89.99,
                discount: 31,
                timeLeft: "3 days",
                icon: "person.3.fill",
                color: .green,
                category: .dataPlan
            )
        ]
    }
    
    private var accessories: [FlashDeal] {
        [
            FlashDeal(
                id: "acc1",
                title: "Signal Booster",
                subtitle: "2x range extension",
                originalPrice: 149.99,
                dealPrice: 99.99,
                discount: 33,
                timeLeft: "6h 20m",
                icon: "antenna.radiowaves.left.and.right",
                color: .purple,
                category: .accessory
            ),
            FlashDeal(
                id: "acc2",
                title: "Smart Adapter",
                subtitle: "IoT optimization",
                originalPrice: 79.99,
                dealPrice: 49.99,
                discount: 38,
                timeLeft: "12h 45m",
                icon: "memorychip",
                color: .teal,
                category: .accessory
            )
        ]
    }
    
    private var premiumDeals: [FlashDeal] {
        [
            FlashDeal(
                id: "prem1",
                title: "Enterprise Suite",
                subtitle: "Business grade",
                originalPrice: 599.99,
                dealPrice: 399.99,
                discount: 33,
                timeLeft: "2 days",
                icon: "building.2",
                color: .indigo,
                category: .premium
            ),
            FlashDeal(
                id: "prem2",
                title: "AI Optimizer",
                subtitle: "Machine learning",
                originalPrice: 199.99,
                dealPrice: 149.99,
                discount: 25,
                timeLeft: "5 days",
                icon: "brain.head.profile",
                color: .pink,
                category: .premium
            )
        ]
    }
}

// MARK: - Auto Moving Tabs
struct AutoMovingTabs: View {
    let tabs: [String]
    @Binding var selectedTab: Int
    let autoScrollInterval: TimeInterval
    
    @State private var timer: Timer?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                        TabButton(
                            title: tab,
                            isSelected: selectedTab == index,
                            action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedTab = index
                                }
                                resetTimer()
                            }
                        )
                        .id(index)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
            .onAppear {
                startAutoScroll()
            }
            .onDisappear {
                stopTimer()
            }
            .onChange(of: selectedTab) { _, newValue in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
    
    private func startAutoScroll() {
        timer = Timer.scheduledTimer(withTimeInterval: autoScrollInterval, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                selectedTab = (selectedTab + 1) % tabs.count
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        // Restart timer after user interaction
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            startAutoScroll()
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Circle()
                        .fill(.white)
                        .frame(width: 6, height: 6)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .clipShape(Capsule())
                    } else {
                        Color.clear
                            .clipShape(Capsule())
                    }
                }
            )
            .overlay(
                Capsule()
                    .stroke(.quaternary, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.3), value: isSelected)
    }
}

// MARK: - Flash Deal Card
struct FlashDealCard: View {
    let deal: FlashDeal
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 16) {
                // Header with icon and timer
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: deal.icon)
                                .font(.title2)
                                .foregroundStyle(deal.color)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(deal.title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                
                                Text(deal.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        // Timer badge
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text(deal.timeLeft)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.red)
                        )
                    }
                    
                    Spacer()
                }
                
                // Pricing section
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("$\(deal.dealPrice, specifier: "%.0f")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(deal.color)
                            
                            HStack(spacing: 4) {
                                Text("$\(deal.originalPrice, specifier: "%.0f")")
                                    .font(.caption)
                                    .strikethrough()
                                    .foregroundColor(.secondary)
                                
                                Text("\(deal.discount)% off")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(.green)
                                    )
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                            .foregroundStyle(deal.color)
                    }
                }
            }
            .padding(16)
            .frame(width: 220, height: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(deal.color.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: deal.color.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onPressGesture(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
    }
}

// MARK: - Flash Deal Model
struct FlashDeal {
    let id: String
    let title: String
    let subtitle: String
    let originalPrice: Double
    let dealPrice: Double
    let discount: Int
    let timeLeft: String
    let icon: String
    let color: Color
    let category: DealCategory
}

enum DealCategory {
    case hotDeal
    case dataPlan
    case accessory
    case premium
}

// MARK: - WiFi Calibration Questionnaire
struct WiFiCalibrationQuestionnaire: View {
    @State private var environmentType: EnvironmentType = .house
    @State private var numberOfFloors: Int = 1
    @Environment(\.dismiss) var dismiss
    
    let onComplete: (CalibrationSetupData) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.gradient)
                    
                    VStack(spacing: 8) {
                        Text("WiFi Calibration Setup")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Tell us about your space to optimize calibration")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: 24) {
                    // Environment Type Question
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "building.2")
                                .font(.title3)
                                .foregroundColor(.blue)
                            
                            Text("What type of building is this?")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: 12) {
                            ForEach([EnvironmentType.house, EnvironmentType.office], id: \.self) { type in
                                EnvironmentTypeCard(
                                    type: type,
                                    isSelected: environmentType == type,
                                    action: { environmentType = type }
                                )
                            }
                        }
                    }
                    
                    // Number of Floors Question
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "stairs")
                                .font(.title3)
                                .foregroundColor(.blue)
                            
                            Text("How many floors does the building have?")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(1...4, id: \.self) { floor in
                                FloorSelectionCard(
                                    number: floor,
                                    isSelected: numberOfFloors == floor,
                                    action: { numberOfFloors = floor }
                                )
                            }
                        }
                        
                        if numberOfFloors > 1 {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Text("You'll calibrate each floor separately during the process")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    let setupData = CalibrationSetupData(
                        environmentType: environmentType,
                        numberOfFloors: numberOfFloors,
                        hasHallways: false // Not asking this question as requested
                    )
                    onComplete(setupData)
                }) {
                    HStack {
                        Text("Start Calibration")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue.gradient)
                    .cornerRadius(12)
                }
            }
            .padding(24)
            .navigationTitle("Setup")
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
}

// MARK: - Environment Type Card
struct EnvironmentTypeCard: View {
    let type: EnvironmentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(isSelected ? .white : .blue)
                
                VStack(spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.blue.gradient)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.clear)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color(UIColor.quaternaryLabel), lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Floor Selection Card
struct FloorSelectionCard: View {
    let number: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("\(number)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(number == 1 ? "Floor" : "Floors")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(width: 70, height: 70)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue.gradient)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.clear)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color(UIColor.quaternaryLabel), lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DashboardView()
        .environmentObject(DashboardViewModel())
}

// MARK: - View Extensions
extension View {
    func onPressGesture(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}
