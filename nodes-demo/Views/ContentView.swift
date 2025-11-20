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
    
    var body: some View {
        Text("""
            Use gestures to move nodes
            Click on the node to show detail information
            """
        )
        .multilineTextAlignment(.center)
        .onAppear {
            Task {
                await openImmersiveSpace(id: "NodeMapView")
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
