//
//  NodeDetailView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//

import SwiftUI

struct NodeDetailView: View {
    @Environment(\.dismiss) var dismissPopover
    var node: Node
    
    var body: some View {
        VStack {
            Text(node.name)
                .font(.largeTitle)
            Text(node.description)
        }
        .padding()
    }
}

#Preview {
    NodeDetailView(node: .init(name: "Test", description: "Description", x: 0, y: 0, z: 0))
}
