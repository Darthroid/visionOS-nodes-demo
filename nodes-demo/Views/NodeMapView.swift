//
//  NodeMapView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct NodeMapView: View {
    @Environment(AppModel.self) var appModel
    @State private var draggedEntity: Entity?
    @State private var nodePositions: [String: SIMD3<Float>] = [:]
    @State private var selectedNodeId: String? = nil
    @State private var entityMap: [String: Entity] = [:]

    var body: some View {
        RealityView { content in
            for node in appModel.nodes {
                let capsuleEntity = createGlassCapsuleNode(for: node)
                entityMap[node.id] = capsuleEntity
                content.add(capsuleEntity)
            }
        }
        .gesture(selectiveDragGesture)
        .gesture(tapGesture)
    }
    
    private var selectiveDragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .targetedToAnyEntity()
            .onChanged { value in
                guard value.entity.components[NodeDataComponent.self] != nil else { return }
                
                if draggedEntity == nil {
                    draggedEntity = value.entity
                    animateEntityScale(value.entity, to: 1.1)
                }
                
                let newPosition = value.convert(value.location3D, from: .local, to: .scene)
                value.entity.position = newPosition
            }
            .onEnded { value in
                guard value.entity.components[NodeDataComponent.self] != nil else { return }
                
                animateEntityScale(value.entity, to: 1.0)
                draggedEntity = nil
            }
    }
    
    private var tapGesture: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                guard let nodeComponent = value.entity.components[NodeDataComponent.self] else { return }
                
                let tappedNodeId = nodeComponent.node.id
                
                if selectedNodeId == tappedNodeId {
                    selectedNodeId = nil
                    updateNodeAppearance(for: tappedNodeId, isSelected: false)
                } else {
                    if let previousSelectedId = selectedNodeId {
                        updateNodeAppearance(for: previousSelectedId, isSelected: false)
                    }
                    
                    selectedNodeId = tappedNodeId
                    updateNodeAppearance(for: tappedNodeId, isSelected: true)
                }
            }
    }

    private func createGlassCapsuleNode(for node: Node) -> Entity {
        let parentEntity = Entity()

        let isSelected = selectedNodeId == node.id
        let (capsuleWidth, capsuleHeight) = calculateDynamicSize(for: node, isSelected: isSelected)
        
        let capsule = createGlassCapsule(width: capsuleWidth, height: capsuleHeight, for: node, isSelected: isSelected)

        let textContent = isSelected && !node.description.isEmpty ?
            "\(node.name)\n\(node.description)" :
            node.name
        
        let text = createGlassCompatibleTextLabel(
            for: textContent,
            containerWidth: capsuleWidth,
            containerHeight: capsuleHeight,
            isSelected: isSelected
        )

        let wrapperEntity = Entity()
        wrapperEntity.addChild(capsule)
        wrapperEntity.addChild(text)

        parentEntity.addChild(wrapperEntity)
        parentEntity.position = SIMD3<Float>(
            node.x,
            node.y,
            node.z
        )
        
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
        
        let textToMeasure = isSelected && !node.description.isEmpty ?
            "\(node.name)\n\(node.description)" :
            node.name
        
        let textLength = Float(textToMeasure.count)
        let calculatedWidth = textLength * staticFontSize * 0.3 + padding
        
        let height = (isSelected && !node.description.isEmpty) ? expandedHeight : baseHeight
        
        return (max(calculatedWidth, minWidth), height)
    }

    private func createGlassCapsule(width: Float, height: Float, for node: Node, isSelected: Bool) -> ModelEntity {
        let cornerRadius: Float = height / 2

        let capsuleMesh = MeshResource.generatePlane(
            width: width,
            height: height,
            cornerRadius: cornerRadius
        )

        // Change color only for selected node
        let material = SimpleMaterial(
            color: isSelected ? .white.withAlphaComponent(1) : .white.withAlphaComponent(0.3),
            roughness: .float(0.1),
            isMetallic: false
        )

        return ModelEntity(mesh: capsuleMesh, materials: [material])
    }

    private func createGlassCompatibleTextLabel(
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
            color: isSelected ? .darkGray : .white,
            roughness: .float(0.8),
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
        let capsule = createGlassCapsule(width: capsuleWidth, height: capsuleHeight, for: node, isSelected: isSelected)
        
        let textContent = isSelected && !node.description.isEmpty ?
            "\(node.name)\n\(node.description)" :
            node.name
        
        let text = createGlassCompatibleTextLabel(
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
    
    private func applyMovementConstraints(position: SIMD3<Float>) -> SIMD3<Float> {
        var constrained = position
        constrained.x = min(max(constrained.x, -1.0), 1.0)
        constrained.y = min(max(constrained.y, -1.0), 1.0)
        constrained.z = min(max(constrained.z, -3.0), -0.5)
        return constrained
    }
    
    private func animateEntityScale(_ entity: Entity, to scale: Float) {
        var transform = entity.transform
        transform.scale = SIMD3<Float>(repeating: scale)
        entity.move(to: transform, relativeTo: entity.parent, duration: 0.15)
    }
}
