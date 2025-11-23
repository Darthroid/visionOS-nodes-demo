//
//  ContentView.swift
//  nodes-demo
//
//  Created by Oleg Komaristy on 17.11.2025.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @State var selectedNodeId: String?
    @State var showNodeForm: Bool = false
    @State var showNodeSpace: Bool = false
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                if appModel.nodes.isEmpty {
                    Text("Press + to add a new node")
                        .foregroundStyle(.secondary)
                } else {
                    List(appModel.nodes, selection: $selectedNodeId) { node in
                        NavigationLink {
                            NodeDetailView(node: node)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(node.name)
                                    .font(.headline)
                                Text(node.positionDescription)
                                    .font(.footnote)
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("Nodes Demo"))
            .toolbar {
                HStack {
                    Button {
                        showNodeForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    
                    Button {
                        showNodeSpace.toggle()
                        if showNodeSpace {
                            Task {
                                await openImmersiveSpace(id: "NodeMapView")
                            }
                        } else {
                            Task {
                                await dismissImmersiveSpace()
                            }
                        }
                    } label: {
                        Image(systemName: "graph.3d")
                    }
                }
            }
        }
        .sheet(isPresented: $showNodeForm) {
            CreateNodeView()
                .environment(appModel)
        }
        .onChange(of: selectedNodeId, { oldValue, newValue in
            appModel.selectedNodeId = newValue
        })
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
