//
//  PasskeyLoginManager.swift
//
//
//  Created by Gaurav Goel on 21/08/24.
//

import AuthenticationServices

class PasskeyLoginManager: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    func signInWithPasskey(registrationResponse: RegistrationResponse) {
        if #available(iOS 15.0, *) {
            let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "web3auth.io")
            let platformKeyRequest = platformProvider.createCredentialAssertionRequest(challenge: registrationResponse.data.options.challenge.data(using: .utf8)!)
            let request = ASAuthorizationPasswordProvider().createRequest()
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASPasswordCredential {
            let username = credential.user
            let password = credential.password
            
            // Use the username and password to authenticate with your backend
            authenticateWithBackend(username: username, password: password)
        }
    }


    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    
        print("Authorization failed: \(error.localizedDescription)")
    }

    // Define where to present the passkey login UI
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow }!
    }

    // Dummy function to demonstrate backend authentication
    func authenticateWithBackend(username: String, password: String) {
        print("Authenticated with backend using username: \(username) and password: \(password)")
    }
}

