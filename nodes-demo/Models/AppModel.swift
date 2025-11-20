//
//  AppModel.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//

import SwiftUI
import Observation
import RealityKit

@MainActor
@Observable
final class AppModel: Sendable {
    var nodes: [Node] = []
    var connections: [NodeConnection] = []
    var selectedNodeId: String?
    
    init() {
        self.nodes = MockData.nodes
        self.connections = MockData.connections
    }
    
    func addNode(name: String, description: String, position: (x: Float, y: Float, z: Float)?) {
        let _position: (x: Float, y: Float, z: Float)
            
            if let providedPosition = position {
                _position = providedPosition
            } else if nodes.isEmpty {
                // If no nodes exist, place in the center
                _position = (0, 0, 0)
            } else {
                // Calculate center position of all existing nodes
                let totalX = nodes.reduce(0.0) { $0 + $1.x }
                let totalY = nodes.reduce(0.0) { $0 + $1.y }
                let totalZ = nodes.reduce(0.0) { $0 + $1.z }
                
                let centerX = totalX / Float(nodes.count)
                let centerY = totalY / Float(nodes.count)
                let centerZ = totalZ / Float(nodes.count)
                
                _position = (centerX, centerY, centerZ)
            }
        
        let node = Node(
            id: UUID().uuidString,
            name: name,
            description: description,
            x: _position.x,
            y: _position.y,
            z: _position.z
        )
        nodes.append(node)
    }
    
    func removeNode(_ node: Node) {
        nodes.removeAll { $0.id == node.id }
        connections.removeAll { $0.fromNodeId == node.id || $0.toNodeId == node.id }
    }
    
    func updatePosition(for nodeId: String, newPosition: SIMD3<Float>) {
        if let index = nodes.firstIndex(where: { $0.id == nodeId }) {
            let oldNode = nodes[index]
            let updatedNode = Node(
                id: oldNode.id,
                name: oldNode.name,
                description: oldNode.description,
                x: newPosition.x,
                y: newPosition.y,
                z: newPosition.z
            )
            
            nodes[index] = updatedNode
        }
    }
    
    func addConnection(from fromNodeId: String, to toNodeId: String) {
        guard fromNodeId != toNodeId,
              nodes.contains(where: { $0.id == fromNodeId }),
              nodes.contains(where: { $0.id == toNodeId }) else { return }
        
        guard !connections.contains(where: {
            ($0.fromNodeId == fromNodeId && $0.toNodeId == toNodeId) ||
            ($0.fromNodeId == toNodeId && $0.toNodeId == fromNodeId)
        }) else { return }
        
        let connection = NodeConnection(
            id: UUID().uuidString,
            fromNodeId: fromNodeId,
            toNodeId: toNodeId
        )
        connections.append(connection)
    }
    
    func removeConnection(_ connection: NodeConnection) {
        connections.removeAll { $0.id == connection.id }
    }
    
}
