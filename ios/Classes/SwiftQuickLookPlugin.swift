import Flutter
import UIKit
import QuickLook

public class SwiftQuickLookPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "quick_look", binaryMessenger: registrar.messenger())
        let instance = SwiftQuickLookPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "openURL" || call.method == "openURLs" else {
            result(false)
            return
        }
        
        var resourceURLs: [String] = []
        
        if let url = call.arguments as? String {
            resourceURLs = [url]
        } else if let urls = call.arguments as? [String] {
            resourceURLs = urls
        } else {
            result(false)
            return
        }
        
        guard !resourceURLs.isEmpty else {
            result(false)
            return
        }
        
        guard let rootViewController = topViewController() else {
            result(false)
            return
        }
        
        let quickLookViewController = QuickLookViewController(resourceURLs, result)
        rootViewController.present(quickLookViewController, animated: true)
    }
    
    private func topViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return nil
    }
}


class QuickLookViewController: UIViewController, QLPreviewControllerDataSource {
    
    var urlsOfResources: [String]
    var shownResource: Bool = false
    var result: FlutterResult
    
    init(_ resourceURLs: [String], _ result: @escaping FlutterResult) {
        self.urlsOfResources = resourceURLs.map{ "file://\($0)"}
        self.result = result
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !shownResource {
            let previewController = QLPreviewController()
            previewController.dataSource = self
            present(previewController, animated: true)
            shownResource = true
        } else {
            self.dismiss(animated: true, completion: { self.result(true) })
        }
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.urlsOfResources.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let url = URL(string: self.urlsOfResources[index])!
        return url as QLPreviewItem
    }
}
