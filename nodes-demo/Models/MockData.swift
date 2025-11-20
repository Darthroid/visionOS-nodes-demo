//
//  MockData.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//

import Foundation

final class MockData {
    static let nodes: [Node] = [
        .init(
            id: "0",
            name: "test node",
            description: "This is a test node",
            x: 0,
            y: 0,
            z: 0
        ),
        .init(
            id: "1",
            name: "node one",
            description: "This is a test node one",
            x: -0.4201641,
            y: 1.5058086,
            z: -1.5
        ),
        .init(
            id: "2",
            name: "node two",
            description: "This is a test node two",
            x: -0.058503926,
            y: 1.4341328,
            z: -1.5
        ),
        .init(
            id: "3",
            name: "node three",
            description: "This is a test node three",
            x: -0.38982427,
            y: 1.3047304,
            z: -1.5
        ),
        .init(
            id: "4",
            name: "very long center node",
            description: "This is a test node with very long description that is placed in the center",
            x: -0.26737112,
            y: 1.4024374,
            z: -1.5
        )
    ]
    
    static let connections: [NodeConnection] = [
        NodeConnection(id: "conn1", fromNodeId: "1", toNodeId: "2"),
//        NodeConnection(id: "conn2", fromNodeId: "2", toNodeId: "3")
    ]
}
