//
//  NodeDetailView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//

import SwiftUI

struct NodeDetailView: View {
    var node: Node
    var onClose: (() -> Void)? = nil
    
    var body: some View {
        VStack {
            Text(node.detail)
            HStack {
                Text("Position:")
                    .fontWeight(.semibold)
                Text(node.positionDescription)
            }
            .font(.caption)
        }
        .navigationTitle(node.name)
        .padding()
    }
}

#Preview {
    NodeDetailView(node: .init(id: UUID().uuidString, name: "Test", detail: "Description", x: 0, y: 0, z: 0))
}
