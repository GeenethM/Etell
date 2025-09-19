//
//  CalibrationSetupFlow.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-23.
//

import SwiftUI

// MARK: - Setup Data Model
struct CalibrationSetupData: Codable {
    var environmentType: EnvironmentType?
    var numberOfFloors: Int?
    var hasHallways: Bool?
}

enum EnvironmentType: String, CaseIterable, Codable {
    case house = "House"
    case apartment = "Apartment"
    case office = "Office"
    
    var icon: String {
        switch self {
        case .house: return "house"
        case .apartment: return "building"
        case .office: return "briefcase"
        }
    }
    
    var description: String {
        switch self {
        case .house: return "Single family home"
        case .apartment: return "Multi-unit building"
        case .office: return "Commercial space"
        }
    }
}

// MARK: - Main Setup Flow View
struct CalibrationSetupFlow: View {
    @State private var setupData = CalibrationSetupData()
    @State private var currentStep = 0
    @Environment(\.dismiss) var dismiss
    
    // Completion handler
    let onComplete: ((CalibrationSetupData) -> Void)?
    
    init(onComplete: ((CalibrationSetupData) -> Void)? = nil) {
        self.onComplete = onComplete
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressBar(currentStep: currentStep, totalSteps: 3)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                // Step content
                TabView(selection: $currentStep) {
                    EnvironmentTypeStep(setupData: $setupData, currentStep: $currentStep)
                        .tag(0)
                    
                    FloorsStep(setupData: $setupData, currentStep: $currentStep)
                        .tag(1)
                    
                    HallwaysStep(setupData: $setupData, currentStep: $currentStep, onComplete: onComplete)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Wi-Fi Environment Setup")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.blue : Color(UIColor.systemGray4))
                    .frame(height: 6)
                    .frame(maxWidth: step <= currentStep ? .infinity : 40)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Step 1: Environment Type
struct EnvironmentTypeStep: View {
    @Binding var setupData: CalibrationSetupData
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("Where are you setting up Wi-Fi?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Select the environment that best matches your location")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 16) {
                ForEach(EnvironmentType.allCases, id: \.self) { type in
                    EnvironmentOptionCard(
                        type: type,
                        isSelected: setupData.environmentType == type
                    ) {
                        setupData.environmentType = type
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Next Button
            Button(action: {
                if setupData.environmentType != nil {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = 1
                    }
                }
            }) {
                Text("Continue")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        setupData.environmentType != nil ? 
                        Color.blue : Color(UIColor.systemGray4)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(setupData.environmentType == nil)
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
    }
}

// MARK: - Environment Option Card
struct EnvironmentOptionCard: View {
    let type: EnvironmentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.blue.opacity(0.1) : Color(UIColor.systemGray6))
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(type.rawValue)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(type.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(20)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.blue : Color(UIColor.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: Number of Floors
struct FloorsStep: View {
    @Binding var setupData: CalibrationSetupData
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("How many floors?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("This helps us understand your space layout")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 16) {
                ForEach(1...3, id: \.self) { floors in
                    FloorOptionCard(
                        floors: floors,
                        isSelected: setupData.numberOfFloors == floors
                    ) {
                        setupData.numberOfFloors = floors
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Navigation Buttons
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = 0
                    }
                }) {
                    Text("Back")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                
                Button(action: {
                    if setupData.numberOfFloors != nil {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = 2
                        }
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            setupData.numberOfFloors != nil ? 
                            Color.blue : Color(UIColor.systemGray4)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(setupData.numberOfFloors == nil)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
    }
}

// MARK: - Floor Option Card
struct FloorOptionCard: View {
    let floors: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: floors == 1 ? "house.fill" : "building.2.fill")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.blue.opacity(0.1) : Color(UIColor.systemGray6))
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(floors) Floor\(floors > 1 ? "s" : "")")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(floors == 1 ? "Single level" : "Multiple levels")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(20)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 3: Hallways
struct HallwaysStep: View {
    @Binding var setupData: CalibrationSetupData
    @Binding var currentStep: Int
    @Environment(\.dismiss) var dismiss
    @State private var showingCalibration = false
    let onComplete: ((CalibrationSetupData) -> Void)?
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("Are there hallways?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Hallways can affect Wi-Fi signal distribution")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 16) {
                HallwayOptionCard(
                    hasHallways: true,
                    isSelected: setupData.hasHallways == true
                ) {
                    setupData.hasHallways = true
                }
                
                HallwayOptionCard(
                    hasHallways: false,
                    isSelected: setupData.hasHallways == false
                ) {
                    setupData.hasHallways = false
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Navigation Buttons
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = 1
                    }
                }) {
                    Text("Back")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                
                Button(action: {
                    if setupData.hasHallways != nil {
                        // Save setup data to service
                        CalibrationSetupService.shared.saveSetupData(setupData)
                        
                        // Call completion handler if provided
                        if let onComplete = onComplete {
                            onComplete(setupData)
                        } else {
                            showingCalibration = true
                        }
                    }
                }) {
                    Text("Start Calibration")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            setupData.hasHallways != nil ? 
                            Color.blue : Color(.systemGray4)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(setupData.hasHallways == nil)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
        .fullScreenCover(isPresented: $showingCalibration) {
            EnhancedCalibrationView()
        }
    }
}

// MARK: - Hallway Option Card
struct HallwayOptionCard: View {
    let hasHallways: Bool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: hasHallways ? "rectangle.split.3x1.fill" : "square.fill")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(hasHallways ? "Yes" : "No")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(hasHallways ? "Has hallways or corridors" : "Open floor plan")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(20)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CalibrationSetupFlow()
}
