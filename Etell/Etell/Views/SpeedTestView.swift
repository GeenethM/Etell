//
//  SpeedTestView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI

struct SpeedTestView: View {
    @StateObject private var viewModel = SpeedTestViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Current Test Display
                SpeedTestGauge()
                
                // Test Controls
                TestControlsSection()
                
                // Test History
                if !viewModel.testResults.isEmpty {
                    TestHistorySection()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Speed Test")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear History") {
                        viewModel.clearHistory()
                    }
                    .disabled(viewModel.testResults.isEmpty)
                }
            }
        }
        .environmentObject(viewModel)
    }
}

struct SpeedTestGauge: View {
    @EnvironmentObject var viewModel: SpeedTestViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Main Speed Display
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: viewModel.progress)
                
                VStack {
                    if viewModel.currentTest == .download {
                        Text("\(viewModel.downloadSpeed, specifier: "%.1f")")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Mbps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if viewModel.currentTest == .upload {
                        Text("\(viewModel.uploadSpeed, specifier: "%.1f")")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Mbps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if viewModel.currentTest == .ping {
                        Text("\(viewModel.ping, specifier: "%.1f")")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("ms")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "speedometer")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Text(viewModel.currentTest.displayText)
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

struct TestControlsSection: View {
    @EnvironmentObject var viewModel: SpeedTestViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await viewModel.startSpeedTest()
                }
            }) {
                Text(viewModel.isRunning ? "Testing..." : "Start Speed Test")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isRunning ? Color.gray : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(viewModel.isRunning)
            
            if viewModel.currentTest == .completed || (!viewModel.isRunning && viewModel.downloadSpeed > 0) {
                SpeedResultsRow()
            }
        }
    }
}

struct SpeedResultsRow: View {
    @EnvironmentObject var viewModel: SpeedTestViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            VStack {
                Text("Download")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(viewModel.downloadSpeed, specifier: "%.1f") Mbps")
                    .font(.headline)
            }
            
            Divider()
                .frame(height: 30)
            
            VStack {
                Text("Upload")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(viewModel.uploadSpeed, specifier: "%.1f") Mbps")
                    .font(.headline)
            }
            
            Divider()
                .frame(height: 30)
            
            VStack {
                Text("Ping")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(viewModel.ping, specifier: "%.1f") ms")
                    .font(.headline)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TestHistorySection: View {
    @EnvironmentObject var viewModel: SpeedTestViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test History")
                .font(.headline)
            
            ForEach(viewModel.testResults.prefix(5)) { result in
                TestHistoryRow(result: result)
            }
        }
    }
}

struct TestHistoryRow: View {
    let result: SpeedTestResult
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("↓ \(result.downloadSpeed, specifier: "%.1f")")
                        .foregroundColor(.green)
                    Text("↑ \(result.uploadSpeed, specifier: "%.1f")")
                        .foregroundColor(.blue)
                    Text("⏱ \(result.ping, specifier: "%.1f")ms")
                        .foregroundColor(.orange)
                }
                .font(.caption)
                
                if let location = result.location {
                    Text(location)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(DateFormatter.shortDate.string(from: result.timestamp))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    SpeedTestView()
}
