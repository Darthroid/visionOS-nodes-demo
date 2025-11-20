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
    var onClose: (() -> Void)? = nil
    
    var body: some View {
        VStack {
            HStack {
                Text(node.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    onClose?()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            Text(node.description)
            HStack {
                Text("Position:")
                    .fontWeight(.semibold)
                Text("(\(String(format: "%.2f", node.x)), \(String(format: "%.2f", node.y)), \(String(format: "%.2f", node.z)))")
            }
            .font(.caption)
        }
        .padding()
    }
}

#Preview {
    NodeDetailView(node: .init(id: UUID().uuidString, name: "Test", description: "Description", x: 0, y: 0, z: 0))
}
