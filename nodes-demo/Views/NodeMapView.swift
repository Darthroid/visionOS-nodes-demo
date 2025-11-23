//
//  NodeMapView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//

import SwiftUI
import RealityKit
import RealityKitContent
import SwiftData

struct NodeMapView: View {
    @Environment(AppModel.self) var appModel
    @State private var draggedEntity: Entity?
    @State private var entityMap: [String: Entity] = [:]
    @State private var connectionMap: [String: ModelEntity] = [:]
    @State private var realityViewContent: RealityViewContent?
    @State var initialDragPosition: SIMD3<Float> = .zero
    
    var body: some View {
        RealityView { content in
            realityViewContent = content
            updateEntities(in: content)
            updateConnections(in: content)
        }
        .gesture(selectiveDragGesture)
        .gesture(tapGesture)
        .onChange(of: appModel.nodes) { oldValue, newValue in
            guard let content = realityViewContent else { return }
            updateEntities(in: content)
            updateConnections(in: content)
        }
        .onChange(of: appModel.connections) { oldValue, newValue in
            guard let content = realityViewContent else { return }
            updateConnections(in: content)
        }
        .onChange(of: appModel.selectedNodeId) { oldValue, newValue in
            let ids = appModel.nodes.map(\.id)
            ids.forEach {
                updateNodeAppearance(for: $0, isSelected: newValue == $0)
            }
        }
    }
    
    // MARK: - Gestures
    
    private var selectiveDragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .targetedToAnyEntity()
            .onChanged { value in
                guard let nodeComponent = value.entity.components[NodeDataComponent.self] else { return }
                
                if draggedEntity == nil {
                    draggedEntity = value.entity
                    animateEntityScale(value.entity, to: 1.1)
                    initialDragPosition = value.entity.position
                }
                
                let movement = value.convert(value.gestureValue.translation3D, from: .local, to: .scene)
                let newPosition = initialDragPosition + movement
                
                value.entity.position = newPosition
                
                appModel.updatePosition(for: nodeComponent.node.id, newPosition: newPosition)
                updateConnectionsForNode(nodeId: nodeComponent.node.id)
            }
            .onEnded { value in
                guard let nodeComponent = value.entity.components[NodeDataComponent.self] else { return }
                
                animateEntityScale(value.entity, to: 1.0)
                draggedEntity = nil
                
                updateConnectionsForNode(nodeId: nodeComponent.node.id)
            }
    }
    
    private var tapGesture: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                guard let nodeComponent = value.entity.components[NodeDataComponent.self] else { return }
                
                let tappedNodeId = nodeComponent.node.id
                
                if appModel.selectedNodeId == tappedNodeId {
                    appModel.selectedNodeId = nil
                    updateNodeAppearance(for: tappedNodeId, isSelected: false)
                } else {
                    if let previousSelectedId = appModel.selectedNodeId {
                        updateNodeAppearance(for: previousSelectedId, isSelected: false)
                    }
                    
                    appModel.selectedNodeId = nodeComponent.node.id
                    updateNodeAppearance(for: tappedNodeId, isSelected: true)
                }
            }
    }
    
// MARK: - Drawing connections

    private func updateEntities(in content: RealityViewContent) {
        let currentNodeIds = Set(appModel.nodes.map { $0.id })
        let existingEntityIds = Set(entityMap.keys)
        
        let removedIds = existingEntityIds.subtracting(currentNodeIds)
        for id in removedIds {
            if let entity = entityMap[id] {
                entity.removeFromParent()
                entityMap.removeValue(forKey: id)
            }
        }
        
        for node in appModel.nodes {
            if let existingEntity = entityMap[node.id] {
                // Update position of existing entity if it changed
                if existingEntity.position != node.position {
                    existingEntity.position = node.position
                    // Connection updates will be handled by the drag gesture
                }
            } else {
                let capsuleEntity = createCapsuleNode(for: node)
                entityMap[node.id] = capsuleEntity
                content.add(capsuleEntity)
            }
        }
    }
    
    private func updateConnections(in content: RealityViewContent) {
        let currentConnectionIds = Set(appModel.connections.map { $0.id })
        let existingConnectionIds = Set(connectionMap.keys)
        
        // Remove old connections
        let removedConnectionIds = existingConnectionIds.subtracting(currentConnectionIds)
        for id in removedConnectionIds {
            if let entity = connectionMap[id] {
                entity.removeFromParent()
                connectionMap.removeValue(forKey: id)
            }
        }
        
        for connection in appModel.connections {
            guard let fromNode = appModel.nodes.first(where: { $0.id == connection.fromNodeId }),
                  let toNode = appModel.nodes.first(where: { $0.id == connection.toNodeId }) else { continue }
            
            if let existingConnection = connectionMap[connection.id] {
                // Update existing connection position and orientation
                updateConnectionEntity(existingConnection, from: fromNode, to: toNode)
            } else {
                // Create new connection
                let connectionEntity = createConnectionEntity(from: fromNode, to: toNode, for: connection)
                connectionMap[connection.id] = connectionEntity
                content.add(connectionEntity)
            }
        }
    }
    
    private func createConnectionEntity(from fromNode: Node, to toNode: Node, for connection: NodeConnection) -> ModelEntity {
        let connectionEntity = ModelEntity()
        
        updateConnectionEntity(connectionEntity, from: fromNode, to: toNode)
        
        // Add connection data component
        connectionEntity.components.set(ConnectionDataComponent(connection: connection))
        
        return connectionEntity
    }
    
    private func updateConnectionEntity(_ connectionEntity: ModelEntity, from fromNode: Node, to toNode: Node) {
        connectionEntity.children.forEach { $0.removeFromParent() }
        
        let startPos = fromNode.position
        let endPos = toNode.position
        
        // Calculate the vector between nodes
        let vector = endPos - startPos
        let distance = length(vector)
        
        // Skip if nodes are too close
        guard distance > 0.01 else { return }
        
        let direction = vector / distance
        
        // Create cylinder for the connection line
        let cylinderRadius: Float = 0.002
        let cylinderMesh = MeshResource.generateCylinder(
            height: distance,
            radius: cylinderRadius
        )
        
        let material = SimpleMaterial(
            color: .darkGray.withAlphaComponent(0.5),
            roughness: .float(0.8),
            isMetallic: false
        )
        
        let cylinder = ModelEntity(mesh: cylinderMesh, materials: [material])
        
        // Position at midpoint between nodes
        cylinder.position = (startPos + endPos) / 2
        
        // Calculate rotation to align cylinder with direction
        // Default cylinder orientation is along Y-axis
        let yAxis: SIMD3<Float> = [0, 1, 0]
        
        // Handle the case where direction is parallel to Y-axis
        if abs(dot(direction, yAxis)) > 0.999 {
            // Use a different approach for parallel vectors
            cylinder.orientation = simd_quatf(angle: 0, axis: [1, 0, 0])
        } else {
            // Calculate rotation using cross product
            let rotationAxis = cross(yAxis, direction)
            let rotationAngle = acos(dot(yAxis, direction))
            cylinder.orientation = simd_quatf(angle: rotationAngle, axis: normalize(rotationAxis))
        }
        
        connectionEntity.addChild(cylinder)
    }
    
    private func updateConnectionsForNode(nodeId: String) {
        // Find all connections involving this node
        let relevantConnections = appModel.connections.filter {
            $0.fromNodeId == nodeId || $0.toNodeId == nodeId
        }
        
        // Update each relevant connection entity
        for connection in relevantConnections {
            guard let connectionEntity = connectionMap[connection.id],
                  let fromNode = appModel.nodes.first(where: { $0.id == connection.fromNodeId }),
                  let toNode = appModel.nodes.first(where: { $0.id == connection.toNodeId }) else { continue }
            
            updateConnectionEntity(connectionEntity, from: fromNode, to: toNode)
        }
    }
    
    // MARK: - Drawing nodes
    
    private func createCapsuleNode(for node: Node) -> Entity {
        let parentEntity = Entity()

        let isSelected = appModel.selectedNodeId == node.id
        let (capsuleWidth, capsuleHeight) = calculateDynamicSize(for: node, isSelected: isSelected)
        
        let capsule = createCapsule(width: capsuleWidth, height: capsuleHeight, for: node, isSelected: isSelected)

        let textContent = isSelected && !node.detail.isEmpty ?
            "\(node.name)\n\(node.detail)" :
            node.name
        
        let text = createTextLabel(
            for: textContent,
            containerWidth: capsuleWidth,
            containerHeight: capsuleHeight,
            isSelected: isSelected
        )

        let wrapperEntity = Entity()
        wrapperEntity.addChild(capsule)
        wrapperEntity.addChild(text)

        parentEntity.addChild(wrapperEntity)
        parentEntity.position = node.position
        
        let collisionShape = ShapeResource.generateBox(width: capsuleWidth, height: capsuleHeight, depth: 0.02)
        parentEntity.components.set(CollisionComponent(
            shapes: [collisionShape],
            mode: .default
        ))
        
        parentEntity.components.set(PhysicsBodyComponent(
            massProperties: .default,
            material: .generate(friction: 0.5, restitution: 0.3),
            mode: .kinematic
        ))
        
        parentEntity.components.set(InputTargetComponent())
        parentEntity.components.set(NodeDataComponent(node: node))
        
        return parentEntity
    }
    
    private func calculateDynamicSize(for node: Node, isSelected: Bool) -> (width: Float, height: Float) {
        let staticFontSize: Float = Constant.fontSize
        let minWidth: Float = 0.1
        let baseHeight: Float = 0.04
        let expandedHeight: Float = 0.06
        let padding: Float = 0.06
        
        let textToMeasure = isSelected && !node.detail.isEmpty ?
            "\(node.name)\n\(node.detail)" :
            node.name
        
        let textLength = Float(textToMeasure.count)
        let calculatedWidth = textLength * staticFontSize * 0.3 + padding
        
        let height = (isSelected && !node.detail.isEmpty) ? expandedHeight : baseHeight
        
        return (max(calculatedWidth, minWidth), height)
    }

    private func createCapsule(width: Float, height: Float, for node: Node, isSelected: Bool) -> ModelEntity {
        let cornerRadius: Float = height / 2

        let capsuleMesh = MeshResource.generatePlane(
            width: width,
            height: height,
            cornerRadius: cornerRadius
        )

        let material = SimpleMaterial(
            color: .white,
            isMetallic: false
        )

        return ModelEntity(mesh: capsuleMesh, materials: [material])
    }

    private func createTextLabel(
        for text: String,
        containerWidth: Float,
        containerHeight: Float,
        isSelected: Bool
    ) -> ModelEntity {
        let staticFontSize: Float = isSelected ? Constant.fontSize * 0.8 : Constant.fontSize
        let textContainerWidth = containerWidth * 0.9
        let textContainerHeight = containerHeight * (isSelected ? 0.8 : 0.6)
        
        let textMesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.003,
            font: isSelected ?
                .systemFont(ofSize: CGFloat(staticFontSize)) :
                .boldSystemFont(ofSize: CGFloat(staticFontSize)),
            containerFrame: CGRect(
                x: -CGFloat(textContainerWidth) / 2,
                y: -CGFloat(textContainerHeight) / (isSelected ? 1.8 : 1.6),
                width: CGFloat(textContainerWidth),
                height: CGFloat(textContainerHeight)
            ),
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )

        let textMaterial = SimpleMaterial(
            color: .darkGray,
            isMetallic: false
        )
        
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        textEntity.position.z = 0.002

        return textEntity
    }
    
    private func updateNodeAppearance(for nodeId: String, isSelected: Bool) {
        guard let entity = entityMap[nodeId],
              let nodeComponent = entity.components[NodeDataComponent.self] else { return }
        
        // Remove all children (capsule and text)
        entity.children.forEach { $0.removeFromParent() }
        
        let node = nodeComponent.node
        let (capsuleWidth, capsuleHeight) = calculateDynamicSize(for: node, isSelected: isSelected)
        
        // Update collision shape
        let collisionShape = ShapeResource.generateBox(width: capsuleWidth, height: capsuleHeight, depth: 0.02)
        entity.components.set(CollisionComponent(
            shapes: [collisionShape],
            mode: .default
        ))
        
        // Create new capsule and text
        let capsule = createCapsule(width: capsuleWidth, height: capsuleHeight, for: node, isSelected: isSelected)
        
        let textContent = isSelected && !node.detail.isEmpty ?
            "\(node.name)\n\(node.detail)" :
            node.name
        
        let text = createTextLabel(
            for: textContent,
            containerWidth: capsuleWidth,
            containerHeight: capsuleHeight,
            isSelected: isSelected
        )
        
        let wrapperEntity = Entity()
        wrapperEntity.addChild(capsule)
        wrapperEntity.addChild(text)
        
        entity.addChild(wrapperEntity)
        
        // Animate scale change
        animateEntityScale(entity, to: isSelected ? 1.2 : 1.0)
    }
    
    private func animateEntityScale(_ entity: Entity, to scale: Float) {
        var transform = entity.transform
        transform.scale = SIMD3<Float>(repeating: scale)
        entity.move(to: transform, relativeTo: entity.parent, duration: 0.15)
    }
}
