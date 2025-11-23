//
//  Node.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//
import Foundation
import RealityKit
import RealityKitContent
import SwiftData

@Model
class Node: Identifiable, Equatable {
    @Attribute(.unique) var id: String
    var name: String
    var detail: String
    var x: Float
    var y: Float
    var z: Float
    
    var position: SIMD3<Float> { .init(x, y, z) }
    var positionDescription: String { "(\(x), \(y), \(z))" }
    
    init(id: String, name: String, detail: String, x: Float, y: Float, z: Float) {
        self.id = id
        self.name = name
        self.detail = detail
        self.x = x
        self.y = y
        self.z = z
    }
}

@Model
class NodeConnection: Identifiable, Equatable {
    @Attribute(.unique) var id: String
    var fromNodeId: String
    var toNodeId: String
    
    init(id: String, fromNodeId: String, toNodeId: String) {
        self.id = id
        self.fromNodeId = fromNodeId
        self.toNodeId = toNodeId
    }
}

struct NodeDataComponent: Component {
    let node: Node
}

struct ConnectionDataComponent: Component {
    let connection: NodeConnection
}
