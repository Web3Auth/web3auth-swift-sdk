//
//  ContentView.swift
//  OpenloginSwiftSdkDemo
//
//  Created by himanshu Chawla on 27/04/21.
//

import SwiftUI
import OpenloginSwiftSdk


class SFViewController: UIViewController {
    public var authentication: Authentication = Authentication()
    override func viewDidLoad() {
           super.viewDidLoad()
           // Do any additional setup after loading the view.
           let button:UIButton = UIButton(frame: CGRect(x: 100, y: 400, width: 200, height: 50))
           button.backgroundColor = .blue
           button.setTitle("Google Login", for: .normal)
           button.addTarget(self, action:#selector(self.buttonAction), for: .touchUpInside)
           self.view.addSubview(button)
    }
       
    @objc func buttonAction(sender: UIButton!) {
        print("button clicked")
        authentication.openlogin.login(controller: self,loginProvider: "google")
        .done{ data in
            print("private key rebuild", data)
          }.catch{ err in
              print(err)
        }
    }
}

struct SFViewControllerRepresentation: UIViewControllerRepresentable {
    var authentication: Authentication
    typealias UIViewControllerType = SFViewController

    func makeUIViewController(context: Context) -> SFViewController {
        let local = SFViewController()
        local.authentication = self.authentication
        return local
    }
    
    func updateUIViewController(_ uiViewController: SFViewController, context: Context) {
        
    }
}
struct ContentView: View {
    @EnvironmentObject var authentication: Authentication
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            SFViewControllerRepresentation(authentication: authentication)
        }
       
    }
}

//struct CotentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
