// MARK: Open SFSafariViewController
import Foundation
import SafariServices

@available(iOS 11.0, *)
open class SFURLHandler: NSObject, SFSafariViewControllerDelegate, OpenloginURLHandlerTypes {
    
    public typealias Transition = (_ controller: SFSafariViewController, _ handler: SFURLHandler) -> Void
    open var present: Transition
    open var dismiss: Transition
    var observers = [String: NSObjectProtocol]()
    
    // configure default presentation and dismissal code
    open var animated: Bool = true
    open var presentCompletion: (() -> Void)?
    open var dismissCompletion: (() -> Void)?
    open var delay: UInt32? = 1
    
    /// init
    public init(viewController: UIViewController) {
        self.present = { [weak viewController] controller, handler in
            viewController?.present(controller, animated: handler.animated, completion: handler.presentCompletion)
        }
        self.dismiss = { [weak viewController] _, handler in
            viewController?.dismiss(animated: handler.animated, completion: handler.dismissCompletion)
        }
    }
    
    public init(present: @escaping Transition, dismiss: @escaping Transition) {
        // self.oauthSwift = oauthSwift
        self.present = present
        self.dismiss = dismiss
    }
    
    @objc open func handle(_ url: URL, modalPresentationStyle: UIModalPresentationStyle = .fullScreen) {
        let controller = SFSafariViewController(url: url)
        controller.modalPresentationStyle = modalPresentationStyle
        controller.dismissButtonStyle = .cancel
        controller.delegate = self
        
        // Present on main queue
        self.present(controller, self)
        
        let key = UUID().uuidString
        
        observers[key] = Openlogin.notificationCenter.addObserver(
            forName: Openlogin.didHandleCallbackURL,
            object: nil,
            queue: OperationQueue.main,
            using: { _ in
                if let observer = self.observers[key] {
                    Openlogin.notificationCenter.removeObserver(observer)
                    self.observers.removeValue(forKey: key)
                }
                self.dismiss(controller, self)
                // TODO: dismiss on main queue
            }
        )
    }
    
    /// Clear internal observers on authentification flow
    open func clearObservers() {
        clearLocalObservers()
        // self.TorusSwiftDirectSDK?.removeCallbackNotificationObserver()
    }
    
    open func clearLocalObservers() {
        for (_, observer) in observers {
            Openlogin.notificationCenter.removeObserver(observer)
        }
        observers.removeAll()
    }
    
    /// SFSafari delegates implementation
    open weak var delegate: SFSafariViewControllerDelegate?
    
    public func safariViewController(_ controller: SFSafariViewController, activityItemsFor URL: Foundation.URL, title: String?) -> [UIActivity] {
        return self.delegate?.safariViewController?(controller, activityItemsFor: URL, title: title) ?? []
    }
    
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        // "Done" pressed
        self.clearObservers()
        self.dismiss(controller, self)
        self.delegate?.safariViewControllerDidFinish?(controller)
    }
    
    public func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        self.delegate?.safariViewController?(controller, didCompleteInitialLoad: didLoadSuccessfully)
    }
    
}

