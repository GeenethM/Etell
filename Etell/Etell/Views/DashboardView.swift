//
//  DashboardView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Connection Status Card
                    ConnectionStatusCard()
                    
                    // Data Usage Card
                    DataUsageCard()
                    
                    // Quick Actions
                    QuickActionsGrid()
                    
                    // Recent Activity
                    RecentActivitySection()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                viewModel.refreshData()
            }
        }
    }
}

struct ConnectionStatusCard: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Connection Status")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(Color(viewModel.connectionStatus.color))
                    .frame(width: 12, height: 12)
            }
            
            Text(viewModel.connectionStatus.displayText)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Current Speed: \(viewModel.currentSpeed)")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DataUsageCard: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Usage")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(viewModel.currentDataUsage, specifier: "%.1f") GB")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("of \(viewModel.dataLimit, specifier: "%.0f") GB")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: viewModel.dataUsagePercentage,
                    color: Color(viewModel.dataUsageColor)
                )
                .frame(width: 60, height: 60)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

struct QuickActionsGrid: View {
    let actions = [
        ("Speed Test", "speedometer", Color.blue),
        ("Signal Check", "wifi", Color.green),
        ("Data Plans", "chart.bar", Color.orange),
        ("Support", "questionmark.circle", Color.purple)
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.bottom, 8)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(actions, id: \.0) { action in
                    QuickActionCard(title: action.0, icon: action.1, color: action.2)
                }
            }
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // Navigation handled by TabView
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentActivitySection: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
            
            ForEach(viewModel.recentActivities.prefix(3)) { activity in
                ActivityRow(activity: activity)
            }
        }
    }
}

struct ActivityRow: View {
    let activity: DashboardViewModel.Activity
    
    var body: some View {
        HStack {
            Image(systemName: iconForActivityType(activity.type))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(timeAgoString(from: activity.timestamp))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func iconForActivityType(_ type: DashboardViewModel.Activity.ActivityType) -> String {
        switch type {
        case .speedTest: return "speedometer"
        case .planChange: return "chart.bar"
        case .deviceConnected: return "iphone"
        case .calibration: return "wifi"
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let days = hours / 24
        
        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else {
            return "Now"
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(DashboardViewModel())
}
