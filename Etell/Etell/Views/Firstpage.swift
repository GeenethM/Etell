//
//  Firstpage.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI

struct FrontPageView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    
    var body: some View {
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // WiFi Logo
                Image(systemName: "wifi")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding(.top, 80)
                
                // App Title
                Text("E-tell")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.blue)
                
                // Subtitle
                Text("Optimize your Wi-Fi experience")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                // Feature highlights
                VStack(spacing: 16) {
                    FeatureRow(icon: "speedometer", title: "Speed Test", description: "Test your internet speed")
                    FeatureRow(icon: "wifi", title: "Signal Optimization", description: "Optimize your router placement")
                    FeatureRow(icon: "chart.bar", title: "Data Plans", description: "Find the perfect plan for you")
                    FeatureRow(icon: "bag", title: "Accessories Store", description: "Get the latest networking gear")
                }
                .padding(.horizontal, 40)
                .padding(.top, 40)
                
                Spacer()
                
                // Get Started Button
                Button(action: {
                    hasSeenWelcome = true
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                        .shadow(radius: 5)
                }
                .padding(.bottom, 60)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    }


struct FrontPageView_Previews: PreviewProvider {
    static var previews: some View {
        FrontPageView()
    }
}

