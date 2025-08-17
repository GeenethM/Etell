# MapKit Tower Calibration Features

## Overview
Enhanced the Etell app's CalibrationView with interactive MapKit functionality to add and manage dummy tower values for sensor calibration.

## New Features Added

### 1. Interactive Map Controls
- **Long Press to Add Towers**: Users can long press anywhere on the map to add new cell towers
- **Tap to Remove Towers**: Users can tap existing towers to remove them from the map
- **Reset Towers**: Button to clear all custom towers and restore default mock towers

### 2. Tower Management Interface
- **Real-time Tower Count**: Display showing current number of towers
- **Signal Strength Visualization**: Color-coded towers based on signal strength:
  - 🟢 Green: 80-100% (Excellent)
  - 🔵 Blue: 60-79% (Good) 
  - 🟠 Orange: 40-59% (Fair)
  - 🔴 Red: Below 40% (Poor)

### 3. Add Tower Sheet
- **Custom Tower Names**: Input field with auto-generated fallback names
- **Signal Strength Slider**: Adjustable from 10% to 100%
- **Location Display**: Shows exact coordinates of the new tower
- **Real-time Preview**: Shows how the tower will appear on the map

### 4. Enhanced Map Display
- **User Location Marker**: Blue pulsing circle showing current location
- **Tower Information**: Each tower shows name and signal percentage
- **Map Controls**: User location button, compass, and scale view

## Technical Implementation

### New Components
- `AddTowerView`: Sheet for creating new towers with custom properties
- `TowerManagementSection`: UI component showing tower statistics and instructions
- Enhanced `MapView`: Interactive map with gesture handling

### New Methods
- `CalibrationViewModel.addTower()`: Adds new tower to the service
- `CalibrationViewModel.removeTower()`: Removes tower by ID
- `CalibrationViewModel.clearAllTowers()`: Resets to default towers
- `SignalCalibrationService.addTower()`: Service method to store tower
- `SignalCalibrationService.removeTower()`: Service method to remove tower

### Map Interactions
- **Long Press Gesture**: Triggers tower creation sheet
- **Tap Gesture**: On towers triggers removal
- **Visual Feedback**: Immediate updates to map annotations

## Usage Instructions

1. **Adding Towers**:
   - Long press anywhere on the map
   - Enter tower name (optional)
   - Adjust signal strength with slider
   - Tap "Add" to create the tower

2. **Removing Towers**:
   - Tap any existing tower on the map
   - Tower is immediately removed

3. **Resetting Towers**:
   - Tap "Reset Towers" button in map header
   - All custom towers are cleared and default towers restored

## Data Model

### Tower Structure
```swift
struct Tower: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let signalStrength: Double // 0.0 to 1.0
}
```

### Default Mock Towers
The app includes 4 default towers positioned around San Francisco:
- Tower 1: (37.7749, -122.4194)
- Tower 2: (37.7849, -122.4094) 
- Tower 3: (37.7649, -122.4294)
- Tower 4: (37.7549, -122.4394)

## Benefits for Sensor Calibration

1. **Realistic Testing Environment**: Custom towers allow testing signal calibration algorithms with various tower configurations
2. **Controlled Signal Simulation**: Adjustable signal strengths enable testing weak/strong signal scenarios
3. **Geographic Accuracy**: Real coordinate system ensures proper distance calculations
4. **User Location Integration**: Calibration measurements relative to actual user position
5. **Dynamic Testing**: Add/remove towers on-the-fly to test different network topologies

## File Changes Made

### Modified Files
- `CalibrationView.swift`: Enhanced with AddTowerView and interactive map
- `CalibrationViewModel.swift`: Added tower management methods
- `SignalCalibrationService.swift`: Added tower storage and manipulation methods

### New Features Integration
- Seamless integration with existing Face ID authentication
- Maintains all previous calibration functionality
- Works with existing signal strength calculations and room calibration system

## Future Enhancements

Potential improvements for the tower calibration system:
1. **Save/Load Tower Configurations**: Persist custom tower setups
2. **Tower Import/Export**: Share tower configurations between devices
3. **Advanced Tower Properties**: Add carrier, frequency, technology type
4. **Heat Map Visualization**: Show signal coverage areas on map
5. **GPS-based Tower Detection**: Automatically detect nearby real towers
