//
//  Node.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//
import Foundation
import RealityKit
import RealityKitContent

struct Node: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let x: Float
    let y: Float
    let z: Float
    
    var position: SIMD3<Float> { .init(x, y, z) }
    var positionDescription: String { "(\(x), \(y), \(z))" }
}

struct NodeConnection: Identifiable, Equatable {
    let id: String
    let fromNodeId: String
    let toNodeId: String
}

struct NodeDataComponent: Component {
    let node: Node
}

struct ConnectionDataComponent: Component {
    let connection: NodeConnection
}
