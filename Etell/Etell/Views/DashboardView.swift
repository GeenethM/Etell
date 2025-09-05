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
                    // Welcome Header
                    WelcomeHeader()
                    
                    // AR Calibration Card
                    ARCalibrationCard()
                    
                    // Signal Map Card
                    SignalMapCard()
                    
                    // Data Plan Card
                    DataPlanCard()
                    
                    // Quick Action Buttons
                    QuickActionButtons()
                    
                    Spacer(minLength: 100) // Space for tab bar
                }
                .padding(.horizontal)
            }
            .navigationBarHidden(true)
        }
    }
}

struct WelcomeHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Hi Geeneth")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("Welcome back to E-tell")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }
        .padding(.top)
    }
}

struct ARCalibrationCard: View {
    @State private var showingSetupFlow = false
    @State private var showingSensorCalibration = false
    
    var body: some View {
        Button(action: {
            showingSetupFlow = true
        }) {
            VStack(spacing: 12) {
                Image(systemName: "sensor.tag.radiowaves.forward")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                Text("Launch Calibration")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Advanced sensor-based WiFi optimization")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingSetupFlow) {
            CalibrationSetupFlow { data in
                // Store data in CalibrationSetupService for persistence
                CalibrationSetupService.shared.saveSetupData(data)
                
                showingSetupFlow = false
                
                // Add a small delay to ensure sheet dismissal completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showingSensorCalibration = true
                }
            }
        }
        .fullScreenCover(isPresented: $showingSensorCalibration) {
            // Get data from the service instead of local state
            let savedData = CalibrationSetupService.shared.getSetupData()
            
            if let setupData = savedData {
                SensorBasedCalibrationView(setupData: setupData)
            } else {
                VStack(spacing: 20) {
                    Text("Setup Data Missing")
                        .font(.title)
                    Text("Please try the setup flow again")
                        .foregroundColor(.gray)
                    Button("Close") {
                        showingSensorCalibration = false
                    }
                    .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                }
            }
        }
    }


struct SignalMapCard: View {
    var body: some View {
        NavigationLink(destination: SignalMapView()) {
            VStack(spacing: 12) {
                Image(systemName: "map")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                
                Text("Open Signal Map")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text("View nearby signal towers")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DataPlanCard: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        NavigationLink(destination: DataPlanView()) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Plan")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("Home 100GB")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: 0.65) // 65GB used out of 100GB
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    HStack {
                        Text("65GB used")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("35GB left")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Text("Expires in 10 days")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickActionButtons: View {
    var body: some View {
        VStack(spacing: 16) {
            // First row
            HStack(spacing: 16) {
                QuickActionButton(
                    icon: "wifi",
                    title: "Speed Test",
                    destination: AnyView(SpeedTestView())
                )
                
                QuickActionButton(
                    icon: "gearshape",
                    title: "Settings",
                    destination: AnyView(ProfileView())
                )
            }
            
            // Second row
            HStack(spacing: 16) {
                QuickActionButton(
                    icon: "headphones",
                    title: "Support",
                    destination: AnyView(CustomerSupportView())
                )
                
                QuickActionButton(
                    icon: "bag",
                    title: "Accessories",
                    destination: AnyView(AccessoriesStoreView())
                )
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
#Preview {
    DashboardView()
        .environmentObject(DashboardViewModel())
}
