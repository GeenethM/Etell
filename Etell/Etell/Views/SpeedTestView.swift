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
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Start Test Button
                    StartTestButton()
                    
                    // Speed Test Gauges
                    SpeedTestGauges()
                    
                    // Last Test Result
                    LastTestResult()
                    
                    // Test History
                    TestHistorySection()
                    
                    Spacer(minLength: 100) // Space for tab bar
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .navigationTitle("Internet Speed Test")
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
        .environmentObject(viewModel)
    }
}

struct StartTestButton: View {
    @EnvironmentObject var viewModel: SpeedTestViewModel
    
    var body: some View {
        Button(action: {
            Task {
                await viewModel.startSpeedTest()
            }
        }) {
            Text(viewModel.isRunning ? "Testing..." : "Start Test")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 150, height: 50)
                .background(viewModel.isRunning ? Color.gray : Color.blue)
                .cornerRadius(25)
        }
        .disabled(viewModel.isRunning)
    }
}

struct SpeedTestGauges: View {
    @EnvironmentObject var viewModel: SpeedTestViewModel
    
    var body: some View {
        HStack(spacing: 30) {
            // Ping Gauge
            SpeedGauge(
                title: "PING",
                value: viewModel.ping,
                unit: "ms",
                progress: viewModel.currentTest == .ping ? viewModel.progress : (viewModel.ping > 0 ? 1.0 : 0.0),
                isActive: viewModel.currentTest == .ping
            )
            
            // Download Gauge
            SpeedGauge(
                title: "DOWNLOAD",
                value: viewModel.downloadSpeed,
                unit: "Mbps",
                progress: viewModel.currentTest == .download ? viewModel.progress : (viewModel.downloadSpeed > 0 ? 1.0 : 0.0),
                isActive: viewModel.currentTest == .download
            )
            
            // Upload Gauge
            SpeedGauge(
                title: "UPLOAD", 
                value: viewModel.uploadSpeed,
                unit: "Mbps",
                progress: viewModel.currentTest == .upload ? viewModel.progress : (viewModel.uploadSpeed > 0 ? 1.0 : 0.0),
                isActive: viewModel.currentTest == .upload
            )
        }
    }
}

struct SpeedGauge: View {
    let title: String
    let value: Double
    let unit: String
    let progress: Double
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(isActive ? Color.blue : Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                
                Circle()
                    .fill(isActive ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            
            if value > 0 {
                Text(String(format: value < 1 ? "%.1f" : "%.0f", value))
                    .font(.headline)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Text("--")
                    .font(.headline)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct LastTestResult: View {
    @EnvironmentObject var viewModel: SpeedTestViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Last test: \(viewModel.testResults.isEmpty ? "Never" : RelativeDateTimeFormatter().localizedString(for: viewModel.testResults.first?.timestamp ?? Date(), relativeTo: Date()))")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct TestHistorySection: View {
    @EnvironmentObject var viewModel: SpeedTestViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Test History")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("See All") {
                    // Show full history
                }
                .foregroundColor(.blue)
                .font(.subheadline)
            }
            
            if viewModel.testResults.isEmpty {
                Text("No test history available")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.testResults.prefix(3)) { result in
                    TestHistoryRow(result: result)
                    
                    if result.id != viewModel.testResults.prefix(3).last?.id {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct TestHistoryRow: View {
    let result: SpeedTestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(DateFormatter.dayTime.string(from: result.timestamp))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(result.location ?? "Home Wifi")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack(spacing: 20) {
                    VStack(alignment: .center, spacing: 2) {
                        Text("PING")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(Int(result.ping)) ms")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("DOWN")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(Int(result.downloadSpeed)) Mbps")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("UP")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(Int(result.uploadSpeed)) Mbps")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

extension DateFormatter {
    static let dayTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, h:mm a"
        return formatter
    }()
}

#Preview {
    SpeedTestView()
}
