import SwiftUI
import SwiftData

struct NodeMapView: View {
    @Environment(AppModel.self) private var appModel
    
    private let pointsPerMeter: CGFloat = 100.0
    private let maxHeight: Float = 2.5 // Maximum height (meters)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid background for spatial reference
                GridView(cellSize: pointsPerMeter, maxHeight: maxHeight, geometry: geometry)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .allowsHitTesting(false)
                
                // Height limit indicator
                HeightLimitView(maxHeight: maxHeight, pointsPerMeter: pointsPerMeter, geometry: geometry)
                    .stroke(Color.red.opacity(0.7), lineWidth: 2)
                    .allowsHitTesting(false)
                
                // Ground level indicator
                GroundLevelIndicatorView(pointsPerMeter: pointsPerMeter, geometry: geometry)
                
                // Height limit label
                HeightLimitLabelView(maxHeight: maxHeight, pointsPerMeter: pointsPerMeter, geometry: geometry)
                
                // Node connections
                ForEach(appModel.connections) { connection in
                    if let fromNode = appModel.node(forId: connection.fromNodeId),
                       let toNode = appModel.node(forId: connection.toNodeId) {
                        ConnectionView(
                            from: convertToViewCoordinates(fromNode.position, in: geometry),
                            to: convertToViewCoordinates(toNode.position, in: geometry)
                        )
                        .stroke(Color.black, lineWidth: 2)
                    }
                }
                
                // Nodes
                ForEach(appModel.nodes) { node in
                    NodeView(node: node, isSelected: appModel.selectedNodeId == node.id)
                        .position(convertToViewCoordinates(node.position, in: geometry))
                        .zIndex(appModel.selectedNodeId == node.id ? 1 : 0) // Selected nodes appear on top
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Convert view coordinates back to world coordinates (meters)
                                    let worldPosition = convertToWorldCoordinates(value.location, in: geometry)
                                    
                                    // Apply height constraint (0 to maxHeight meters)
                                    let constrainedY = min(max(worldPosition.y, 0), CGFloat(maxHeight))
                                    
                                    appModel.updatePosition(
                                        for: node.id,
                                        newPosition: SIMD3<Float>(
                                            Float(worldPosition.x),
                                            Float(constrainedY),
                                            node.z
                                        )
                                    )
                                }
                        )
                        .onTapGesture {
                            appModel.selectedNodeId = appModel.selectedNodeId == node.id ? nil : node.id
                        }
                        .animation(.spring(response: 0.3), value: node.position)
                }
            }
        }
        .background(Color.white)
    }
    
    /// Convert world coordinates (meters) to view coordinates (points)
    /// Zero point at bottom of view (ground level), Y increases upward to maxHeight at top
    private func convertToViewCoordinates(_ worldPosition: SIMD3<Float>, in geometry: GeometryProxy) -> CGPoint {
        let viewX = CGFloat(worldPosition.x) * pointsPerMeter + geometry.size.width / 2
        // Map Y coordinate: 0m at bottom, maxHeight at top
        let viewY = geometry.size.height - (CGFloat(worldPosition.y) / CGFloat(maxHeight)) * geometry.size.height
        return CGPoint(x: viewX, y: viewY)
    }
    
    /// Convert view coordinates (points) to world coordinates (meters)
    /// Zero point at bottom of view (ground level), Y increases upward to maxHeight at top
    private func convertToWorldCoordinates(_ viewPosition: CGPoint, in geometry: GeometryProxy) -> CGPoint {
        let worldX = (viewPosition.x - geometry.size.width / 2) / pointsPerMeter
        // Map Y coordinate: bottom is 0m, top is maxHeight
        let worldY = (1.0 - (viewPosition.y / geometry.size.height)) * CGFloat(maxHeight)
        return CGPoint(x: worldX, y: worldY)
    }
}

struct NodeView: View {
    let node: Node
    let isSelected: Bool
    @State var showDetail: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(spacing: 8) {
                Text(node.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.init(uiColor: .darkGray))
                    .multilineTextAlignment(.center)
                
                if isSelected {
                    Text(node.detail.isEmpty ? "No description" : node.detail)
                        .font(.system(size: 14))
                        .foregroundColor(.init(uiColor: .darkGray).opacity(node.detail.isEmpty ? 0.6 : 0.9))
                        .multilineTextAlignment(.center)
                }
            }
            
            if isSelected {
                Button {
                    showDetail.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.init(uiColor: .darkGray))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .stroke(.gray, lineWidth: 1)
                .fill(node.color ?? .white)
                .shadow(
                    color: .black.opacity(isSelected ? 0.5 : 0.3),
                    radius: isSelected ? 10 : 6,
                    x: 0, y: isSelected ? 5 : 3
                )
        )
        .frame(maxWidth: 400)
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .sheet(isPresented: $showDetail) {
            NavigationStack {
                NodeDetailView(node: node)
            }
        }
    }
}

struct ConnectionView: Shape {
    let from: CGPoint
    let to: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        return path
    }
}

// Grid background for spatial reference
struct GridView: Shape {
    let cellSize: CGFloat
    let maxHeight: Float
    let geometry: GeometryProxy
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let centerX = geometry.size.width / 2
        
        // Vertical lines
        var x: CGFloat = centerX.truncatingRemainder(dividingBy: cellSize)
        while x < geometry.size.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: geometry.size.height))
            x += cellSize
        }
        
        // Horizontal lines (every 0.5 meters in world coordinates)
        for height in stride(from: 0.0, through: Double(maxHeight), by: 0.5) {
            let viewY = geometry.size.height - (CGFloat(height) / CGFloat(maxHeight)) * geometry.size.height
            path.move(to: CGPoint(x: 0, y: viewY))
            path.addLine(to: CGPoint(x: geometry.size.width, y: viewY))
        }
        
        return path
    }
}

// Height limit indicator
struct HeightLimitView: Shape {
    let maxHeight: Float
    let pointsPerMeter: CGFloat
    let geometry: GeometryProxy
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Height limit is at the top (y = 0)
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
        
        return path
    }
}

// Height limit label
struct HeightLimitLabelView: View {
    let maxHeight: Float
    let pointsPerMeter: CGFloat
    let geometry: GeometryProxy
    
    var body: some View {
        VStack {
            HStack {
                Text("Height Limit: \(String(format: "%.1f", maxHeight)) m")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.9))
                    )
                Spacer()
            }
            .padding(.leading, 8)
            .padding(.top, 4)
            Spacer()
        }
    }
}

// Ground level indicator
struct GroundLevelIndicatorView: View {
    let pointsPerMeter: CGFloat
    let geometry: GeometryProxy
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Text("Ground Level (0m)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.9))
                    )
                Spacer()
            }
            .padding(.leading, 8)
            .padding(.bottom, 4)
        }
    }
}

#Preview {
    let appModel = AppModel()
    return NodeMapView()
        .environment(appModel)
}
