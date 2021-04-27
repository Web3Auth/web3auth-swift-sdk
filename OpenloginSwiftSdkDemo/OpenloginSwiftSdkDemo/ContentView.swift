//
//  ContentView.swift
//  OpenloginSwiftSdkDemo
//
//  Created by himanshu Chawla on 27/04/21.
//

import SwiftUI
 import OpenloginSwiftSdk
struct ContentView: View {
    var body: some View {
        VStack {
            Button("Login") {
                let op = OpenloginSdk()
                op.help(message: "aheke")
                op.noHelp(message: "dkd")
            }
            Text("Hello, world!")
                .padding()
        }
       
    }
}

struct CotentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
