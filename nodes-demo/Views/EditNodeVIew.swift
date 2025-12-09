//
//  EditNodeVIew.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 04.12.2025.
//


import SwiftUI

struct EditNodeView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.dismiss) var dismiss
    
    var nodeId: String
    @State var name: String
    @State var detail: String
    
    var body: some View {
        NavigationStack {
            VStack{
//                Form {
                    TextField(text: $name, axis: .vertical) {
                        Text("Name")
                    }
                    .lineLimit(2...3)
                    .textFieldStyle(.roundedBorder)
                    
                    TextField(text: $detail, axis: .vertical) {
                        Text("Description")
                    }
                    .lineLimit(5...10)
                    .textFieldStyle(.roundedBorder)
//                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    
                    Button("Save") {
                        appModel.updateNode(id: nodeId, name: name, detail: detail)
                        dismiss()
                    }
                    .disabled(name.isEmpty && detail.isEmpty)
                }
            }
            .padding()
            .navigationTitle(Text("Edit Node"))
        }
    }
}
