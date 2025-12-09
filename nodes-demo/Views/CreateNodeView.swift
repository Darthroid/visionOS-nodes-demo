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
                    
                    Button("Create") {
                        appModel.addNode(name: name, detail: detail, position: nil)
                        dismiss()
                    }
                    .disabled(name.isEmpty && detail.isEmpty)
                }
            }
            .padding()
            .navigationTitle(Text("Create Node"))
        }
    }
}
