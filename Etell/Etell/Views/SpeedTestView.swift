//
//  SpeedTestView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI

struct SpeedTestView: View {
    @StateObject private var viewModel = SpeedTestViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Hero Section with Start Button
                    ModernHeroSection()
                        .environmentObject(viewModel)
                    
                    // Speed Test Gauges
                    ModernSpeedGaugesSection()
                        .environmentObject(viewModel)
                    
                    // Current Test Status
                    if viewModel.isRunning {
                        ModernTestStatusCard()
                            .environmentObject(viewModel)
                    }
                    
                    // Results Summary
                    if !viewModel.testResults.isEmpty {
                        ModernResultsSummary()
                            .environmentObject(viewModel)
                    }
                    
                    // Test History
                    ModernTestHistorySection()
                        .environmentObject(viewModel)
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(.ultraThinMaterial.opacity(0.5))
            .navigationTitle("Speed Test")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await viewModel.refreshHistory()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            Task {
                                await viewModel.refreshHistory()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.blue)
                        }
                        
                        Button {
                            // Show settings or info
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .environmentObject(viewModel)
    }
}

// MARK: - Hero Section
struct ModernHeroSection: View {
    @EnvironmentObject var viewModel: SpeedTestViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Status Text
            Text(viewModel.currentTest.displayText)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .animation(.easeInOut, value: viewModel.currentTest)
            
            // Main Action Button
            Button {
                Task {
                    await viewModel.startSpeedTest()
                }
            } label: {
                HStack(spacing: 12) {
                    if viewModel.isRunning {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.white)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.title3)
                    }
                    
                    Text(viewModel.isRunning ? "Testing..." : "Start Speed Test")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: viewModel.isRunning ? 
                        [.gray.opacity(0.8), .gray] : 
                        [.blue, .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                .scaleEffect(viewModel.isRunning ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isRunning)
            }
            .disabled(viewModel.isRunning)
            
            // Network Info
            HStack(spacing: 16) {
                Label("WiFi Connected", systemImage: "wifi")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Divider()
                    .frame(height: 12)
                
                Label("Good Signal", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Speed Gauges Section
struct ModernSpeedGaugesSection: View {
    @EnvironmentObject var viewModel: SpeedTestViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Connection Speed")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack(spacing: 16) {
                ModernSpeedGauge(
                    title: "Ping",
                    value: viewModel.ping,
                    unit: "ms",
                    progress: viewModel.currentTest == .ping ? viewModel.progress : (viewModel.ping > 0 ? 1.0 : 0.0),
                    isActive: viewModel.currentTest == .ping,
                    color: .orange
                )
                
                ModernSpeedGauge(
                    title: "Download",
                    value: viewModel.downloadSpeed,
                    unit: "Mbps",
                    progress: viewModel.currentTest == .download ? viewModel.progress : (viewModel.downloadSpeed > 0 ? 1.0 : 0.0),
                    isActive: viewModel.currentTest == .download,
                    color: .green
                )
                
                ModernSpeedGauge(
                    title: "Upload",
                    value: viewModel.uploadSpeed,
                    unit: "Mbps",
                    progress: viewModel.currentTest == .upload ? viewModel.progress : (viewModel.uploadSpeed > 0 ? 1.0 : 0.0),
                    isActive: viewModel.currentTest == .upload,
                    color: .blue
                )
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Modern Speed Gauge
struct ModernSpeedGauge: View {
    let title: String
    let value: Double
    let unit: String
    let progress: Double
    let isActive: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(.quaternary, lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isActive ? 
                        LinearGradient(colors: [color, color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [color.opacity(0.8), color.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                
                // Center content
                VStack(spacing: 2) {
                    if value > 0 {
                        Text(String(format: value < 1 ? "%.1f" : "%.0f", value))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    } else {
                        Text("--")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Text(unit)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                
                // Active indicator
                if isActive {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .offset(y: -50)
                        .scaleEffect(isActive ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isActive)
                }
            }
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isActive ? color : .secondary)
                .animation(.easeInOut, value: isActive)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Test Status Card
struct ModernTestStatusCard: View {
    @EnvironmentObject var viewModel: SpeedTestViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundStyle(.blue)
                    .font(.title3)
                
                Text("Testing in Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(viewModel.progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: viewModel.progress)
                .tint(.blue)
                .scaleEffect(y: 1.5)
            
            Text(viewModel.currentTest.displayText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Results Summary
struct ModernResultsSummary: View {
    @EnvironmentObject var viewModel: SpeedTestViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Latest Result")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if let lastResult = viewModel.testResults.first {
                    Text(RelativeDateTimeFormatter().localizedString(for: lastResult.timestamp, relativeTo: Date()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let lastResult = viewModel.testResults.first {
                HStack(spacing: 20) {
                    ModernResultMetric(
                        title: "Ping",
                        value: "\(Int(lastResult.ping))",
                        unit: "ms",
                        icon: "timer",
                        color: .orange
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    ModernResultMetric(
                        title: "Download",
                        value: "\(Int(lastResult.downloadSpeed))",
                        unit: "Mbps",
                        icon: "arrow.down.circle.fill",
                        color: .green
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    ModernResultMetric(
                        title: "Upload",
                        value: "\(Int(lastResult.uploadSpeed))",
                        unit: "Mbps",
                        icon: "arrow.up.circle.fill",
                        color: .blue
                    )
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Result Metric
struct ModernResultMetric: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Test History Section
struct ModernTestHistorySection: View {
    @EnvironmentObject var viewModel: SpeedTestViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Test History")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            if viewModel.testResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    
                    Text("No test history")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text("Run your first speed test to see results here")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.testResults.prefix(5).enumerated()), id: \.element.id) { index, result in
                        ModernTestHistoryRow(result: result)
                        
                        if index < min(4, viewModel.testResults.count - 1) {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Test History Row
struct ModernTestHistoryRow: View {
    let result: SpeedTestResult
    
    var body: some View {
        HStack(spacing: 16) {
            // Time indicator
            VStack(spacing: 4) {
                Text(DateFormatter.timeOnly.string(from: result.timestamp))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(DateFormatter.dayOnly.string(from: result.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 60)
            
            // Location
            VStack(alignment: .leading, spacing: 2) {
                Text(result.location ?? "Home WiFi")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "wifi")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("Connected")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Results
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(Int(result.ping))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("ms")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 2) {
                    Text("\(Int(result.downloadSpeed))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                    Text("down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 2) {
                    Text("\(Int(result.uploadSpeed))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                    Text("up")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

// MARK: - Date Formatters
extension DateFormatter {
    static let dayTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, h:mm a"
        return formatter
    }()
    
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    static let dayOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

#Preview {
    SpeedTestView()
}
