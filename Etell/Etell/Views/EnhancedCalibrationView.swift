//
//  EnhancedCalibrationView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-23.
//

import SwiftUI

struct EnhancedCalibrationView: View {
    @StateObject private var viewModel = EnhancedCalibrationViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Bar
                if viewModel.currentStep != .completed {
                    CalibrationProgressBar(
                        currentStep: viewModel.currentStep,
                        totalLocations: viewModel.calibratedLocations.count
                    )
                    .padding(.horizontal)
                }
                
                // Main Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch viewModel.currentStep {
                        case .instructions:
                            InstructionsStepView()
                                .environmentObject(viewModel)
                        case .calibrating:
                            CalibratingStepView()
                                .environmentObject(viewModel)
                        case .locationDetails:
                            LocationDetailsStepView()
                                .environmentObject(viewModel)
                        case .nextRoom:
                            NextRoomStepView()
                                .environmentObject(viewModel)
                        case .completed:
                            CompletedStepView()
                                .environmentObject(viewModel)
                        }
                        
                        // Calibrated Locations List
                        if !viewModel.calibratedLocations.isEmpty && viewModel.currentStep != .completed {
                            CalibratedLocationsList()
                                .environmentObject(viewModel)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Room Calibration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if !viewModel.calibratedLocations.isEmpty && viewModel.currentStep != .completed {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Finish") {
                            viewModel.finishCalibration()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .onAppear {
                viewModel.startCalibrationFlow()
            }
            .sheet(isPresented: $viewModel.showingLocationDetails) {
                LocationDetailsSheet()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $viewModel.showingResults) {
                CalibrationResultsView()
                    .environmentObject(viewModel)
            }
        }
    }
}

// MARK: - Progress Bar
struct CalibrationProgressBar: View {
    let currentStep: CalibrationStep
    let totalLocations: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Room \(totalLocations + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(totalLocations) calibrated")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progressValue)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
        .padding(.vertical, 10)
    }
    
    private var progressValue: Double {
        switch currentStep {
        case .instructions: return 0.0
        case .calibrating: return 0.25
        case .locationDetails: return 0.75
        case .nextRoom: return 1.0
        case .completed: return 1.0
        }
    }
}

// MARK: - Instructions Step
struct InstructionsStepView: View {
    @EnvironmentObject var viewModel: EnhancedCalibrationViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Go to the room to calibrate")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Move to the room where you want to measure WiFi signal strength")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                Text("Instructions:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    InstructionRow(number: "1", text: "Go to the room you want to calibrate")
                    InstructionRow(number: "2", text: "Tap 'Start Calibration' when ready")
                    InstructionRow(number: "3", text: "Wait for the signal measurement")
                    InstructionRow(number: "4", text: "Specify room type and floor")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button(action: {
                viewModel.startRoomCalibration()
            }) {
                Text("Start Calibration")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
    }
}

struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 24, height: 24)
                .overlay(
                    Text(number)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Calibrating Step
struct CalibratingStepView: View {
    @EnvironmentObject var viewModel: EnhancedCalibrationViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: viewModel.calibrationProgress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: viewModel.calibrationProgress)
                    
                    VStack {
                        Text("\(Int(viewModel.calibrationProgress * 100))%")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Calibrating")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("Measuring signal strength...")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Please keep your device steady while we measure the WiFi signal")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Real-time signal display
            SignalStrengthCard(strength: viewModel.currentSignalStrength)
        }
    }
}

struct SignalStrengthCard: View {
    let strength: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "wifi")
                    .foregroundColor(signalColor)
                Text("Current Signal")
                    .font(.headline)
                Spacer()
                Text("\(Int(strength * 100))%")
                    .font(.headline)
                    .foregroundColor(signalColor)
            }
            
            ProgressView(value: strength)
                .progressViewStyle(LinearProgressViewStyle(tint: signalColor))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var signalColor: Color {
        switch strength {
        case 0.7...1.0: return .green
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }
}

// MARK: - Location Details Step
struct LocationDetailsStepView: View {
    @EnvironmentObject var viewModel: EnhancedCalibrationViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Location calibrated successfully!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            Text("Please specify the details for this location")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Location Details Sheet
struct LocationDetailsSheet: View {
    @EnvironmentObject var viewModel: EnhancedCalibrationViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("What type of location is this?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Help us understand this space better")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Location Type Selection
                VStack(spacing: 12) {
                    ForEach(LocationType.allCases, id: \.self) { type in
                        LocationTypeCard(
                            type: type,
                            isSelected: viewModel.selectedLocationType == type
                        ) {
                            viewModel.selectedLocationType = type
                        }
                    }
                }
                
                // Floor Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Which floor?")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ForEach(1...3, id: \.self) { floor in
                            Button(action: {
                                viewModel.selectedFloor = floor
                            }) {
                                Text("\(floor)")
                                    .font(.headline)
                                    .foregroundColor(viewModel.selectedFloor == floor ? .white : .blue)
                                    .frame(width: 50, height: 50)
                                    .background(viewModel.selectedFloor == floor ? Color.blue : Color.clear)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.blue, lineWidth: 2)
                                    )
                                    .cornerRadius(25)
                            }
                        }
                        Spacer()
                    }
                }
                
                // Custom Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Name (Optional)")
                        .font(.headline)
                    
                    TextField("Enter location name", text: $viewModel.customLocationName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.saveCurrentLocation()
                    dismiss()
                }) {
                    Text("Save Location")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.selectedLocationType != nil ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(viewModel.selectedLocationType == nil)
            }
            .padding()
            .navigationTitle("Location Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LocationTypeCard: View {
    let type: LocationType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(type.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Circle()
                    .strokeBorder(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                    .background(Circle().fill(isSelected ? Color.blue : Color.clear))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding()
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Next Room Step
struct NextRoomStepView: View {
    @EnvironmentObject var viewModel: EnhancedCalibrationViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Location Saved!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Move to the next room you want to calibrate")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    viewModel.moveToNextRoom()
                }) {
                    Text("Calibrate Next Room")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    viewModel.finishCalibration()
                }) {
                    Text("Finish Calibration")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                        .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Calibrated Locations List
struct CalibratedLocationsList: View {
    @EnvironmentObject var viewModel: EnhancedCalibrationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calibrated Locations (\(viewModel.calibratedLocations.count))")
                .font(.headline)
            
            ForEach(viewModel.calibratedLocations, id: \.id) { location in
                CalibratedLocationRow(location: location)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CalibratedLocationRow: View {
    let location: CalibratedLocation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: location.type.icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Floor \(location.floor) • \(location.type.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(location.signalStrength * 100))%")
                    .font(.headline)
                    .foregroundColor(signalColor)
                
                Text(DateFormatter.timeFormatter.string(from: location.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var signalColor: Color {
        switch location.signalStrength {
        case 0.7...1.0: return .green
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }
}

// MARK: - Completed Step
struct CompletedStepView: View {
    @EnvironmentObject var viewModel: EnhancedCalibrationViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("Calibration Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("We've analyzed \(viewModel.calibratedLocations.count) locations and generated recommendations")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                viewModel.showingResults = true
            }) {
                Text("View Results & Recommendations")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    EnhancedCalibrationView()
}
