//
//  Node.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//
import Foundation
import RealityKit
import RealityKitContent

struct Node {
    let name: String
    let description: String
    let x: Float
    let y: Float
    let z: Float
}

struct NodeDataComponent: Component {
    let node: Node
}
