
## Overview

A visionOS demo application showcasing mind mapping in both 2D and immersive XR environments. This app demonstrates spatial computing capabilities, SwiftUI integration with RealityKit, and seamless transitions between traditional and extended reality interfaces.

## Features
- Create, edit, and connect nodes using visionOS gestures
- 2D Canvas: Traditional mind mapping interface with touch and pointer interactions
- XR Immersion: Fully spatial 3D environment where mind maps extend into your physical space
- Real-time Transitions: Smooth switching between 2D and XR modes

## Screenshots

![2d map](/Screenshots/map_2d.png)
![2d node detail](/Screenshots/node_detail_2d.png)

![xr map](/Screenshots/map_xr.png)
![xr node detail](/Screenshots/node_detail_xr.png)


## Key Technical Features

- Seamless transitions between 2D and XR using SwiftUI's scene management
- Custom RealityKit entities for 3D node visualization
- Gesture recognition for both touch and spatial interactions
- State synchronization between 2D and XR environments

## Setup & Installation

### Requirements

- visionOS 2.0 or later
- Xcode 26.0+
- Apple Vision Pro (simulator or device)

### Building the Project

- Clone the repository
- Open SpatialMindMap.xcodeproj in Xcode
- Build and run on visionOS Simulator or Apple Vision Pro

### Running the App

- Launch the app from the Home View
- Start with the 2D canvas for initial mind map creation
- Tap the grid button (in the top right corner) to transition to immersive mode
- Use pinch gestures to interact with nodes in both modes

## Future Enhancements

### Potential areas for expansion:

- Multiple canvas support
- Collaborative multi-user XR sessions
- AI-powered node suggestions and auto-organization
- Additional export formats and integrations
- Custom node templates and visualization styles
- Advanced spatial layout algorithms
