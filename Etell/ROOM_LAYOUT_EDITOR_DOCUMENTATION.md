# 2D Room Layout Editor with Drag-and-Drop WiFi Optimization

## Overview
The 2D Room Layout Editor is an interactive visual tool that allows users to arrange their calibrated rooms on a grid-based canvas to match their actual floor plan. This spatial arrangement enables advanced WiFi placement recommendations based on room adjacency and signal propagation patterns.

## Key Features

### 🎯 **Interactive Room Arrangement**
- **Drag & Drop**: Move room cards freely around the canvas
- **Resizable Rooms**: Adjust room dimensions by dragging corner handles
- **Grid Snapping**: Optional snap-to-grid for precise alignment
- **Multi-Floor Support**: Toggle between different floors with tabs
- **Visual Feedback**: Real-time updates with shadows and scaling effects

### 📐 **Grid-Based Canvas**
- **20px Grid System**: Precise positioning with optional grid snapping
- **Visual Grid Lines**: Light gray grid for alignment reference
- **Canvas Size**: 300x400 point workspace with scrollable content
- **Background Grid**: Semi-transparent overlay for positioning guidance

### 🏢 **Multi-Floor Management**
- **Floor Tabs**: Switch between Floor 1, Floor 2, Floor 3
- **Independent Layouts**: Each floor maintains separate room arrangements
- **Room Count Display**: Shows number of rooms per floor in tabs
- **Floor-Specific Analysis**: WiFi recommendations per floor

### 📊 **Room Visualization**
- **Color-Coded Signal Strength**:
  - **Green**: Strong signal (70-100%)
  - **Orange**: Moderate signal (40-70%)
  - **Red**: Weak signal (0-40%)
- **Room Type Icons**: House, corridor, stairs icons
- **Signal Percentage**: Real-time signal strength display
- **Selection Highlighting**: White border for selected rooms

## User Workflow

### 1. Access Layout Editor
```
Calibration Results → "Arrange Your Room Layout" Button → Layout Editor
```

### 2. Room Arrangement Process
1. **Select Floor**: Tap floor tabs to switch between levels
2. **Drag Rooms**: Move room cards to approximate positions
3. **Resize Rooms**: Drag corner handles to adjust dimensions
4. **Fine-tune Layout**: Use grid snapping for precision
5. **Generate Plan**: Tap "Generate WiFi Plan" for recommendations

### 3. Advanced WiFi Analysis
1. **Adjacency Calculation**: System detects which rooms are adjacent
2. **Centrality Analysis**: Calculates optimal router positions
3. **Signal Propagation**: Models WiFi coverage based on layout
4. **Extender Placement**: Suggests optimal extender positions

## Technical Implementation

### Data Models

#### `DraggableRoom`
```swift
struct DraggableRoom {
    let calibratedLocation: CalibratedLocation
    var position: CGPoint          // Canvas position
    var size: CGSize              // Room dimensions
    var floor: Int               // Floor number
    var isSelected: Bool         // Selection state
}
```

#### `RoomLayoutData`
```swift
struct RoomLayoutData {
    var rooms: [DraggableRoom]    // Current floor rooms
    var floors: [FloorLayout]     // All floor data
    var currentFloor: Int         // Active floor
    var gridSize: CGSize         // Canvas dimensions
    var snapToGrid: Bool         // Grid snapping toggle
}
```

#### `FloorLayout`
```swift
struct FloorLayout {
    let floor: Int
    var rooms: [DraggableRoom]
    var adjacencyMap: [UUID: Set<UUID>]  // Room relationships
}
```

### WiFi Analysis Algorithms

#### 1. **Adjacency Detection**
```swift
private func areRoomsAdjacent(_ room1: DraggableRoom, _ room2: DraggableRoom) -> Bool {
    let threshold: CGFloat = 10 // Proximity threshold
    let rect1 = CGRect(origin: room1.position, size: room1.size)
    let rect2 = CGRect(origin: room2.position, size: room2.size)
    let expandedRect1 = rect1.insetBy(dx: -threshold, dy: -threshold)
    return expandedRect1.intersects(rect2)
}
```

#### 2. **Centrality Scoring**
```swift
private func calculateCentralityScore(for room: DraggableRoom, in floor: FloorLayout) -> Double {
    // Calculate geometric center distance to all other rooms
    // Lower average distance = higher centrality score
    // Range: 0.0 to 1.0
}
```

#### 3. **Router Optimization**
```swift
private func findOptimalRouterPosition(for floor: FloorLayout) -> RouterRecommendation? {
    // Combine centrality (40%) + signal strength (40%) + room type bonus (20%)
    // Prefer main living areas with good signal and central location
}
```

#### 4. **Extender Placement**
```swift
private func findOptimalExtenderPositions(for floor: FloorLayout) -> [LayoutExtenderRecommendation] {
    // Find weak signal rooms (< 50%)
    // Locate adjacent rooms with strong signal
    // Calculate optimal placement between weak and strong areas
}
```

## UI Components

### **RoomLayoutEditorView** - Main Container
- Navigation with cancel/generate buttons
- Instructions header with visual cues
- Floor tab bar for multi-level navigation
- Grid layout area with room cards
- Controls footer with settings and info

### **GridLayoutArea** - Interactive Canvas
- Geometry reader for responsive sizing
- Grid background with visual guides
- Draggable room cards with gesture handling
- Tap-to-deselect background interaction

### **DraggableRoomCard** - Interactive Room Element
- Drag gesture for repositioning
- Resize handles when selected
- Visual feedback (scaling, shadows)
- Color-coded signal strength
- Room name and percentage display

### **FloorTabBar** - Multi-Floor Navigation
- Horizontal tab layout
- Active floor highlighting
- Room count per floor
- Smooth switching animations

### **ControlsFooter** - Settings and Information
- Selected room details
- Grid snapping toggle
- Room count and floor display
- Contextual help information

## WiFi Recommendations Output

### **Coverage Analysis**
- **Total Rooms**: Count of all calibrated locations
- **Well Covered**: Rooms with 70%+ signal strength
- **Weak Areas**: Rooms with <40% signal strength
- **Coverage Percentage**: Overall network health score

### **Router Placement Recommendations**
- **Optimal Location**: Best room for main router
- **Reasoning**: Detailed explanation of choice
- **Score**: Quantified recommendation confidence (0-100)
- **Layout Preview**: Visual representation on floor plan

### **Extender Recommendations**
- **Target Areas**: Specific weak signal locations
- **Placement Suggestions**: Optimal extender positions
- **Signal Improvement**: Expected signal boost percentage
- **Priority Levels**: High/Medium/Low implementation priority

### **Implementation Guide**
1. **Router Placement**: Move main router to recommended location
2. **Install Extenders**: Place WiFi extenders in suggested spots
3. **Test Coverage**: Re-run calibration to verify improvements
4. **Fine-tune**: Adjust positions based on real-world performance

## Advanced Features

### **Intelligent Layout Analysis**
- **Room Relationship Mapping**: Detects adjacent rooms automatically
- **Signal Propagation Modeling**: Considers walls and obstacles
- **Multi-Floor Coordination**: Analyzes vertical signal distribution
- **Optimal Path Finding**: Calculates best signal routes

### **Visual Feedback System**
- **Real-time Grid Snapping**: Visual alignment guides
- **Selection Highlighting**: Clear selected state indication
- **Drag Shadows**: Depth perception during movement
- **Resize Handles**: Intuitive corner manipulation points

### **Data Persistence**
- **Layout Saving**: Maintains room arrangements between sessions
- **Multi-Floor State**: Preserves each floor's configuration
- **Settings Memory**: Remembers grid snapping preferences
- **Recommendation History**: Stores analysis results

## Performance Optimizations

### **Efficient Rendering**
- **Canvas-based Grid**: Optimized background drawing
- **Conditional Updates**: Only re-render changed elements
- **Gesture Optimization**: Smooth drag and resize operations
- **Memory Management**: Proper state cleanup

### **Algorithm Efficiency**
- **Spatial Indexing**: Fast adjacency calculations
- **Memoized Results**: Cache expensive computations
- **Incremental Updates**: Only recalculate when layout changes
- **Background Processing**: Non-blocking analysis operations

## Integration Points

### **From Calibration Results**
```swift
// Launch layout editor with calibrated data
RoomLayoutEditorView(calibratedLocations: viewModel.calibratedLocations)
```

### **To WiFi Recommendations**
```swift
// Generate intelligent recommendations
let recommendations = WiFiLayoutAnalyzer.analyze(layoutData: layoutData)
```

### **With Existing System**
- **Seamless Navigation**: Integrated with calibration flow
- **Data Compatibility**: Uses existing CalibratedLocation model
- **State Management**: Maintains app-wide consistency
- **Theme Matching**: Consistent visual design language

## Future Enhancements

### **Planned Features**
1. **Auto-Layout**: AI-powered room arrangement suggestions
2. **3D Visualization**: Three-dimensional floor plan representation
3. **AR Integration**: Augmented reality room scanning
4. **Cloud Sync**: Multi-device layout synchronization
5. **Export Options**: PDF reports and image sharing
6. **Professional Mode**: Advanced settings for IT professionals

### **Advanced Analysis**
1. **Machine Learning**: Improve recommendations over time
2. **Real-time Updates**: Live signal strength monitoring
3. **Environmental Factors**: Consider walls, furniture, interference
4. **Bandwidth Optimization**: Multi-router mesh analysis
5. **Cost Analysis**: Hardware recommendation with pricing

This comprehensive 2D Room Layout Editor transforms the WiFi calibration experience from a simple signal measurement tool into an intelligent, visual network planning system that provides actionable, spatially-aware recommendations for optimal WiFi coverage.
