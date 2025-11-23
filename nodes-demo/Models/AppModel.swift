//
//  AppModel.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//

import SwiftUI
import Observation
import RealityKit
import SwiftData

@MainActor
@Observable
final class AppModel: Sendable {
    var container: ModelContainer?
    
    var context: ModelContext? {
        container?.mainContext
    }
    
    
    var nodes: [Node] = []
    var connections: [NodeConnection] = []
    var selectedNodeId: String?
    
    init() {
        self.nodes = MockData.nodes
        self.connections = MockData.connections
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false, allowsSave: true)
        self.container = try? ModelContainer(
            for: NodeConnection.self, Node.self,
            configurations: configuration
        )
        
        fetchItems()
    }
    
    func node(forId id: String) -> Node? {
        return nodes.first(where: { $0.id == id })
    }
    
    func addNode(name: String, detail: String, position: (x: Float, y: Float, z: Float)?) {
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
            detail: detail,
            x: _position.x,
            y: _position.y,
            z: _position.z
        )
        
        context?.insert(node)
        try? context?.save()
        fetchItems()
    }
    
    func removeNode(_ node: Node) {
        let nodeId = node.id
        context?.delete(node)
        try? context?.delete(model: NodeConnection.self, where: #Predicate<NodeConnection> { item in
            item.fromNodeId == nodeId || item.toNodeId == nodeId
        })
        try? context?.save()
        fetchItems()
    }
    
    func updatePosition(for nodeId: String, newPosition: SIMD3<Float>) {
        if let objectToUpdate = try? context?.fetch(FetchDescriptor<Node>(predicate: #Predicate { $0.id == nodeId })).first {
            objectToUpdate.x = newPosition.x
            objectToUpdate.y = newPosition.y
            objectToUpdate.z = newPosition.z
        }
        try? context?.save()
        fetchItems()
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
        context?.insert(connection)
        try? context?.save()
        fetchItems()
    }
    
    func removeConnection(_ connection: NodeConnection) {
        context?.delete(connection)
        try? context?.save()
        fetchItems()
    }
    
    func fetchItems() {
        do {
            let nodeDescriptor = FetchDescriptor<Node>(sortBy: [SortDescriptor(\.name)])
            let connectionsDescriptor = FetchDescriptor<NodeConnection>(sortBy: [SortDescriptor(\.id)])
            nodes = try context?.fetch(nodeDescriptor) ?? []
            connections = try context?.fetch(connectionsDescriptor) ?? []
        } catch {
            print("Failed to fetch items: \(error)")
        }
    }
}
