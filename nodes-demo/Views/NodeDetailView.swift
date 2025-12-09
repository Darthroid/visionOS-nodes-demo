//
//  NodeDetailView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//

import SwiftUI

struct NodeDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppModel.self) var appModel
    
    @State var showDeleteConfirmation: Bool = false
    
    @State var showEditor: Bool = false
    
    @State var showLinkEditor: Bool = false
    
    var node: Node
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Description:")
                .font(.title)
                .padding(.bottom)
            if node.detail.isEmpty {
                Text("No description")
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            } else {
                Text(node.detail)
            }
            
            Text("Position:")
                .font(.title)
                .padding(.vertical)
            Text(node.positionDescriptionMeters)
            
            if appModel.hasConnection(nodeId: node.id) {
                Text("Connected Nodes")
                    .font(.title)
                    .padding(.vertical)
                List(appModel.nodesConnectedWith(node: node)) { connectedNode in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(connectedNode.name)
                                .font(.headline)
                            Text(connectedNode.positionDescription)
                                .font(.footnote)
                        }
                        
                        Spacer()
                        
                        Button {
                            appModel.removeConnectionsBetween(connectedNode, and: node)
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
                .listStyle(.plain)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button {
                    showDeleteConfirmation.toggle()
                } label: {
                    Text("Delete")
                }
                
                Button("Link") {
                    showLinkEditor.toggle()
                }
                
                Button {
                    showEditor.toggle()
                } label: {
                    Text("Edit")
                }
                
            }
        }
        .toolbar {
            Button {
                dismiss()
            } label: {
                Text("Done")
            }
        }
        .navigationTitle(node.name)
        .sheet(isPresented: $showEditor) {
            EditNodeView(nodeId: node.id, name: node.name, detail: node.detail)
        }
        .sheet(isPresented: $showLinkEditor) {
            LinkEditorView(fromNode: node)
        }
        .alert(
            Text("Delete node"),
            isPresented: $showDeleteConfirmation,
            actions: {
                Button(role: .destructive) {
                    showDeleteConfirmation.toggle()
                    dismiss()
                    appModel.removeNode(node)
                } label: {
                    Text("Delete")
                }
                Button(role: .cancel) {
                    //
                } label: {
                    Text("Cancel")
                }

            },
            message: {
                Text("Are you sure you want to delete this node?")
            })
        
        .padding()
    }
}

#Preview {
    NodeDetailView(node: .init(id: UUID().uuidString, name: "Test", detail: "Description", x: 0, y: 0, z: 0))
}
