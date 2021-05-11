import SwiftUI
import OpenloginSwiftSdk

class SFViewController: UIViewController {
    var authentication = Authentication()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI
        let button = UIButton(frame: CGRect(x: 100, y: 400, width: 200, height: 50))
        button.backgroundColor = .blue
        button.setTitle("Sign in", for: .normal)
        button.addTarget(self, action:#selector(self.signIn), for: .touchUpInside)
        self.view.addSubview(button)
        
        // Configure auth
        self.authentication =  Authentication(controller: self)
    }
    
    @objc func signIn(sender: UIButton!) {
        authentication.openlogin.login(params: ["loginProvider":"google"])
            .done{ data in
                print("Signed in", data)
            }.catch{ err in
                print(err)
            }
    }
}

struct SFViewControllerRepresentation: UIViewControllerRepresentable {
    typealias UIViewControllerType = SFViewController
    
    func makeUIViewController(context: Context) -> SFViewController {
        return SFViewController()
    }
    
    func updateUIViewController(_ uiViewController: SFViewController, context: Context) {
    }
}

struct ContentView: View {
    @EnvironmentObject var authentication: Authentication
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            SFViewControllerRepresentation()
        }
    }
}

struct CotentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
