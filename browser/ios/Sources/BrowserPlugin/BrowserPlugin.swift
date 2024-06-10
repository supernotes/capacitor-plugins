import Foundation
import Capacitor

@objc(CAPBrowserPlugin)
public class CAPBrowserPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "CAPBrowserPlugin"
    public let jsName = "Browser"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "open", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "close", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "startWebAuthSession", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = Browser()

    @objc func open(_ call: CAPPluginCall) {
        // validate the URL
        guard let urlString = call.getString("url"), let url = URL(string: urlString) else {
            call.reject("Must provide a valid URL to open")
            return
        }
        // extract the optional parameters
        var color: UIColor?
        if let toolbarColor = call.getString("toolbarColor") {
            color = UIColor.capacitor.color(fromHex: toolbarColor)
        }
        let style = self.presentationStyle(for: call.getString("presentationStyle"))
        // prepare for display
        guard implementation.prepare(for: url, withTint: color, modalPresentation: style), let viewController = implementation.viewController else {
            call.reject("Unable to display URL")
            return
        }
        implementation.browserEventDidOccur = { [weak self] (event) in
            self?.notifyListeners(event.listenerEvent, data: nil)
        }
        // display
        DispatchQueue.main.async { [weak self] in
            if style == .popover {
                if let width = call.getInt("width"), let height = call.getInt("height") {
                    self?.setCenteredPopover(viewController, size: CGSize.init(width: width, height: height))
                } else {
                    self?.setCenteredPopover(viewController)
                }
            }
            self?.bridge?.presentVC(viewController, animated: true, completion: {
                call.resolve()
            })
        }
    }

    @objc func close(_ call: CAPPluginCall) {
        DispatchQueue.main.async { [weak self] in
            if self?.implementation.viewController != nil {
                self?.bridge?.dismissVC(animated: true) {
                    call.resolve()
                    self?.implementation.cleanup()
                }
            } else {
                call.reject("No active window to close!")
            }
        }
    }
    
    @objc func startWebAuthSession(_ call: CAPPluginCall) {
        guard let urlString = call.getString("url"), let url = URL(string: urlString),
              let callbackURLScheme = call.getString("callbackURLScheme") else {
            call.reject("Must provide a valid URL and callback URL scheme to start web auth session")
            return
        }
        let useWebAuthSession = call.getBool("useWebAuthSession") ?? false
        
        guard implementation.prepareWebAuthSession(for: url, callbackURLScheme: callbackURLScheme, useWebAuthSession: useWebAuthSession) else {
            call.reject("Unable to prepare web authentication session")
            return
        }
        
        implementation.browserEventDidOccur = { [weak self] (event) in
            self?.notifyListeners(event.listenerEvent, data: nil)
        }
        
        DispatchQueue.main.async { [weak self] in
            if self?.implementation.startWebAuthSession() == true {
                call.resolve()
            } else {
                call.reject("Failed to start web authentication session")
            }
        }
    }

    private func presentationStyle(for style: String?) -> UIModalPresentationStyle {
        if let style = style, style == "popover" {
            return .popover
        }
        return .fullScreen
    }
}

private extension BrowserEvent {
    var listenerEvent: String {
        switch self {
        case .loaded:
            return "browserPageLoaded"
        case .finished:
            return "browserFinished"
        }
    }
}
