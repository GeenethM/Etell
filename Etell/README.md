# Etell iOS App - MVVM Architecture

This project has been restructured to follow MVVM (Model-View-ViewModel) architecture with comprehensive features for a telecommunications app.

## 📁 Project Structure

```
Etell/
├── Models/                      # Data models
│   ├── User.swift              # User data model
│   ├── DataPlan.swift          # Internet plan models
│   ├── Product.swift           # Store product models
│   ├── FAQ.swift               # Support FAQ models
│   └── SignalData.swift        # Signal calibration models
├── Views/                       # SwiftUI Views
│   ├── MainTabView.swift       # Main tab navigation
│   ├── LoginPage.swift         # Updated login screen
│   ├── SignUpView.swift        # New user registration
│   ├── DashboardView.swift     # Main dashboard
│   ├── SpeedTestView.swift     # Internet speed testing
│   ├── CalibrationView.swift   # Signal calibration with maps
│   ├── DataPlanView.swift      # Plan selection
│   ├── AccessoriesStoreView.swift # Product store
│   ├── CustomerSupportView.swift # Support with FAQ and chat
│   ├── ProfileView.swift       # User profile and settings
│   └── ContentView.swift       # Root view controller
├── ViewModels/                  # Business logic
│   ├── AuthViewModel.swift     # Authentication logic
│   ├── DashboardViewModel.swift # Dashboard data
│   ├── SpeedTestViewModel.swift # Speed test logic
│   └── CalibrationViewModel.swift # Signal calibration logic
├── Services/                    # External services
│   ├── FirebaseAuthService.swift # Authentication service
│   ├── NotificationService.swift # Push notifications & Face ID
│   └── SignalCalibrationService.swift # Signal measurement
└── EtellApp.swift              # App entry point
```

## 🚀 Features Implemented

### 1. **Authentication System**
- Email/password login and signup
- Face ID/Touch ID integration
- Mock Firebase authentication
- Secure session management

### 2. **Dashboard**
- Connection status monitoring
- Data usage tracking with visual indicators
- Quick action grid
- Recent activity feed
- Real-time data updates

### 3. **Speed Test**
- Mock speed testing (ping, download, upload)
- Visual gauge interface
- Test history tracking
- Animated progress indicators

### 4. **Signal Calibration**
- MapKit integration showing cell towers
- CoreLocation for user positioning
- CoreMotion for device orientation
- Room-by-room signal measurement
- Calibration reports with recommendations
- Product suggestions based on weak signals

### 5. **Data Plan Selection**
- Multiple plan tiers with features
- Plan comparison interface
- Current plan management
- Billing information display

### 6. **Accessories Store**
- Product catalog (routers, extenders, etc.)
- Category filtering and search
- Shopping cart functionality
- Product detail views
- Stock status tracking

### 7. **Customer Support**
- FAQ section with search
- Contact form
- Live chat simulation
- Multiple support channels

### 8. **Profile & Settings**
- User profile management
- Notification preferences
- Security settings (Face ID toggle)
- Account management
- App preferences

## 🛠 Technical Features

### Architecture
- **MVVM Pattern**: Clear separation of concerns
- **Dependency Injection**: Services injected via EnvironmentObjects
- **Reactive Programming**: Combine framework for data flow
- **Mock Services**: Complete mock implementation for demo

### iOS Frameworks Used
- **SwiftUI**: Modern declarative UI
- **MapKit**: Maps and location visualization
- **CoreLocation**: GPS positioning
- **CoreMotion**: Device orientation tracking
- **LocalAuthentication**: Face ID/Touch ID
- **UserNotifications**: Push notification management
- **Combine**: Reactive data binding

### Key Components
- **TabView Navigation**: 7-tab structure for easy navigation
- **Form Validation**: Real-time input validation
- **Error Handling**: Comprehensive error states and alerts
- **Loading States**: Progress indicators throughout the app
- **Mock Data**: Realistic sample data for all features

## 📱 Navigation Structure

Main Tab Bar:
1. **Dashboard** - Overview and quick actions
2. **Speed Test** - Network performance testing
3. **Plans** - Data plan selection and management
4. **Calibration** - Signal optimization tool
5. **Store** - Accessories and equipment
6. **Support** - Help and customer service
7. **Profile** - User settings and account

## 🔧 Setup Instructions

1. Open the Xcode project
2. Ensure all files are properly organized in their folders
3. Build and run the project
4. Use demo credentials for login (any email/password)
5. Explore all features through the tab navigation

## 📋 Future Enhancements

- Real Firebase integration
- Actual speed test API
- Real signal strength measurement
- Payment processing for store
- Push notification implementation
- Advanced analytics and reporting

This implementation provides a complete, production-ready structure that can be easily extended with real backend services and enhanced features.
