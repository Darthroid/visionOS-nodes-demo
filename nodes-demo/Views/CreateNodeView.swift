//
//  CreateNodeView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 20.11.2025.
//

import SwiftUI

struct CreateNodeView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.dismiss) var dismiss
    
    @State var name: String = ""
    @State var detail: String = ""
    
    var body: some View {
        NavigationStack {
            VStack{
                Form {
                    TextField(text: $name) {
                        Text("Name")
                    }
                    
                    TextField(text: $detail) {
                        Text("Description")
                    }
                }
                
                HStack {
                    Button("Create") {
                        appModel.addNode(name: name, detail: detail, position: nil)
                        dismiss()
                    }
                    .disabled(name.isEmpty && detail.isEmpty)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .padding()
            .navigationTitle(Text("Create Node"))
        }
    }
}
