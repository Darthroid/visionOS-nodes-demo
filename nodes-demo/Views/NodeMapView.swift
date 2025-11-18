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
    let nodes: [Node] = [
        .init(
            name: "test node",
            description: "This is a test node",
            x: 0,
            y: 0,
            z: 0
        ),
        .init(
            name: "node one",
            description: "This is a test node",
            x: -0.4201641,
            y: 1.5058086,
            z: -1.5
        ),.init(
            name: "node two",
            description: "This is a test node",
            x: -0.058503926,
            y: 1.4341328,
            z: -1.5
        ),
        .init(
            name: "node three",
            description: "This is a test node",
            x: -0.38982427,
            y: 1.3047304,
            z: -1.5
        ),
        .init(
            name: "very long center node",
            description: "This is a test node",
            x: -0.26737112,
            y: 1.4024374,
            z: -1.5
        )
    ]
    
    @State private var draggedEntity: Entity?
    @State private var nodePositions: [String: SIMD3<Float>] = [:]

    var body: some View {
        RealityView { content in
            for node in nodes {
                let capsuleEntity = createGlassCapsuleNode(for: node)
                content.add(capsuleEntity)
            }
        }
        .gesture(selectiveDragGesture)
    }
    
    private var selectiveDragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .targetedToAnyEntity()
            .onChanged { value in
                // Filter entities by name or component
                guard value.entity.components[NodeDataComponent.self] != nil else { return }
                
                if draggedEntity == nil {
                    draggedEntity = value.entity
                    animateEntityScale(value.entity, to: 1.1)
                }
                
                let newPosition = value.convert(value.location3D, from: .local, to: .scene)
                value.entity.position = applyMovementConstraints(position: newPosition)
            }
            .onEnded { value in
                guard value.entity.components[NodeDataComponent.self] != nil else { return }
                
                animateEntityScale(value.entity, to: 1.0)
                draggedEntity = nil
            }
    }

    private func createGlassCapsuleNode(for node: Node) -> Entity {
        let parentEntity = Entity()

        let (capsuleWidth, capsuleHeight) = calculateDynamicSize(for: node.name)
        
        let capsule = createGlassCapsule(width: capsuleWidth, height: capsuleHeight, for: node.name)

        let text = createGlassCompatibleTextLabel(for: node.name, containerWidth: capsuleWidth, containerHeight: capsuleHeight)

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
    
    private func calculateDynamicSize(for text: String) -> (width: Float, height: Float) {
        let staticFontSize: Float = Constant.fontSize
        let minWidth: Float = 0.1
        let baseHeight: Float = 0.04
        let padding: Float = 0.06 // Padding
        
        let textLength = Float(text.count)
        let calculatedWidth = textLength * staticFontSize * 0.4 + padding
        
        return (max(calculatedWidth, minWidth), baseHeight)
    }

    private func createGlassCapsule(width: Float, height: Float, for nodeName: String) -> ModelEntity {
        let cornerRadius: Float = height / 2

        let capsuleMesh = MeshResource.generatePlane(
            width: width,
            height: height,
            cornerRadius: cornerRadius
        )

        let material = SimpleMaterial(
            color: .white.withAlphaComponent(0.3),
            roughness: .float(0.1),
            isMetallic: false
        )

        return ModelEntity(mesh: capsuleMesh, materials: [material])
    }

    private func createGlassCompatibleTextLabel(for text: String, containerWidth: Float, containerHeight: Float) -> ModelEntity {
        let staticFontSize: Float = Constant.fontSize
        let textContainerWidth = containerWidth * 0.9  // 90% of capsule width
        let textContainerHeight = containerHeight * 0.6 // 60% of capsule height
        
        let textMesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.003,
            font: .boldSystemFont(ofSize: CGFloat(staticFontSize)),
            containerFrame: CGRect(
                x: -CGFloat(textContainerWidth) / 2,
                y: -CGFloat(textContainerHeight) / 1.6,
                width: CGFloat(textContainerWidth),
                height: CGFloat(textContainerHeight)
            ),
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )

        let textMaterial = SimpleMaterial(
            color: .white,
            roughness: .float(0.8),
            isMetallic: false
        )
        
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])

        textEntity.position.z = 0.002

        return textEntity
    }

    private func convertToVisionOSPosition(node: Node) -> SIMD3<Float> {
        let scaleFactor: Float = 0.001
        let x = Float(node.x) * scaleFactor
        let y = -Float(node.y) * scaleFactor
        let xOffset: Float = 0.5
        let yOffset: Float = 1

        return SIMD3<Float>(
            x + xOffset,
            y + yOffset,
            Float(node.z)
        )
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
