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
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressBar(currentStep: currentStep, totalSteps: 3)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Step content
                TabView(selection: $currentStep) {
                    EnvironmentTypeStep(setupData: $setupData, currentStep: $currentStep)
                        .tag(0)
                    
                    FloorsStep(setupData: $setupData, currentStep: $currentStep)
                        .tag(1)
                    
                    HallwaysStep(setupData: $setupData, currentStep: $currentStep, onComplete: onComplete)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
            .navigationTitle("Wi-Fi Environment Setup")
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

// MARK: - Progress Bar
struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .animation(.easeInOut, value: currentStep)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Step 1: Environment Type
struct EnvironmentTypeStep: View {
    @Binding var setupData: CalibrationSetupData
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Where are you setting up Wi-Fi?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Select the environment that best matches your location")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
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
            .padding(.horizontal)
            
            Spacer()
            
            // Next Button
            Button(action: {
                if setupData.environmentType != nil {
                    withAnimation {
                        currentStep = 1
                    }
                }
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(setupData.environmentType != nil ? Color.blue : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(setupData.environmentType == nil)
            .padding(.horizontal)
            .padding(.bottom, 30)
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

// MARK: - Step 2: Number of Floors
struct FloorsStep: View {
    @Binding var setupData: CalibrationSetupData
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("How many floors?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("This helps us understand your space layout")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
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
            .padding(.horizontal)
            
            Spacer()
            
            // Navigation Buttons
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        currentStep = 0
                    }
                }) {
                    Text("Back")
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
                
                Button(action: {
                    if setupData.numberOfFloors != nil {
                        withAnimation {
                            currentStep = 2
                        }
                    }
                }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(setupData.numberOfFloors != nil ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(setupData.numberOfFloors == nil)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
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
                Image(systemName: floors == 1 ? "house" : "building.2")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(floors) Floor\(floors > 1 ? "s" : "")")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(floors == 1 ? "Single level" : "Multiple levels")
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

// MARK: - Step 3: Hallways
struct HallwaysStep: View {
    @Binding var setupData: CalibrationSetupData
    @Binding var currentStep: Int
    @Environment(\.dismiss) var dismiss
    @State private var showingCalibration = false
    let onComplete: ((CalibrationSetupData) -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Are there hallways?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Hallways can affect Wi-Fi signal distribution")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
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
            .padding(.horizontal)
            
            Spacer()
            
            // Navigation Buttons
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        currentStep = 1
                    }
                }) {
                    Text("Back")
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
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(setupData.hasHallways != nil ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(setupData.hasHallways == nil)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
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
                Image(systemName: hasHallways ? "rectangle.split.3x1" : "square")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(hasHallways ? "Yes" : "No")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(hasHallways ? "Has hallways or corridors" : "Open floor plan")
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

#Preview {
    CalibrationSetupFlow()
}
